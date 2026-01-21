# Phase 2: Supabase Database Migration Implementation Plan

## Overview

This plan details the migration from localStorage to Supabase database for the Focus First Learning App. The goal is to persist user data in Supabase while maintaining backward compatibility for unauthenticated users.

## Current State Analysis

### Existing Implementation
- **localStorage keys**: `signal_queue`, `focus-first-history`
- **Data structures**: `QueueItem` and `ArchiveItem` interfaces in `types/index.ts`
- **Auth**: Working Supabase auth via `context/AuthContext.tsx`
- **Client**: Supabase browser client in `lib/supabase/client.ts`

### Database Schema (as specified)
```sql
-- queue_items table
CREATE TABLE queue_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  raw_content TEXT NOT NULL,
  header TEXT NOT NULL,
  summary TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'queued',
  source_url TEXT,
  category TEXT,
  complexity_score INTEGER,
  sequence_order INTEGER,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- archive_items table
CREATE TABLE archive_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  header TEXT NOT NULL,
  summary TEXT NOT NULL,
  source_url TEXT,
  learned_at TIMESTAMPTZ DEFAULT NOW()
);

-- RLS Policies
ALTER TABLE queue_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE archive_items ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can only access their own queue items"
  ON queue_items FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Users can only access their own archive items"
  ON archive_items FOR ALL USING (auth.uid() = user_id);
```

---

## Implementation Details

### 1. Database Types (`types/database.ts`)

Create TypeScript types that match the Supabase schema:

```typescript
// types/database.ts
export interface Database {
  public: {
    Tables: {
      queue_items: {
        Row: {
          id: string
          user_id: string
          raw_content: string
          header: string
          summary: string
          status: string
          source_url: string | null
          category: string | null
          complexity_score: number | null
          sequence_order: number | null
          created_at: string
        }
        Insert: Omit<Database['public']['Tables']['queue_items']['Row'], 'id' | 'created_at'> & {
          id?: string
          created_at?: string
        }
        Update: Partial<Database['public']['Tables']['queue_items']['Insert']>
      }
      archive_items: {
        Row: {
          id: string
          user_id: string
          header: string
          summary: string
          source_url: string | null
          learned_at: string
        }
        Insert: Omit<Database['public']['Tables']['archive_items']['Row'], 'id' | 'learned_at'> & {
          id?: string
          learned_at?: string
        }
        Update: Partial<Database['public']['Tables']['archive_items']['Insert']>
      }
    }
  }
}

// Helper type for converting DB row to app type
export type DbQueueItem = Database['public']['Tables']['queue_items']['Row']
export type DbArchiveItem = Database['public']['Tables']['archive_items']['Row']
```

---

### 2. useQueue Hook (`hooks/useQueue.ts`)

```typescript
// hooks/useQueue.ts
'use client'

import { useState, useEffect, useCallback, useRef } from 'react'
import { createClient } from '@/lib/supabase/client'
import { useAuth } from '@/context/AuthContext'
import { QueueItem } from '@/types'

const STORAGE_KEY = 'signal_queue'
const MIGRATION_KEY = 'signal_queue_migrated'

interface UseQueueReturn {
  queue: QueueItem[]
  isLoading: boolean
  error: string | null
  addItem: (item: Omit<QueueItem, 'id' | 'createdAt' | 'status'>) => Promise<QueueItem | null>
  removeItem: (id: string) => Promise<boolean>
  updateItem: (id: string, updates: Partial<QueueItem>) => Promise<boolean>
  reorderQueue: (reorderedItems: QueueItem[]) => Promise<boolean>
  markAsLearned: (id: string) => Promise<QueueItem | null>
  refetch: () => Promise<void>
}

// Convert DB row to app QueueItem
function dbToQueueItem(row: {
  id: string
  raw_content: string
  header: string
  summary: string
  status: string
  source_url: string | null
  category: string | null
  complexity_score: number | null
  sequence_order: number | null
  created_at: string
}): QueueItem {
  return {
    id: row.id,
    rawContent: row.raw_content,
    header: row.header,
    summary: row.summary,
    status: row.status as 'queued' | 'completed',
    sourceUrl: row.source_url,
    category: row.category ?? undefined,
    complexityScore: row.complexity_score ?? undefined,
    sequenceOrder: row.sequence_order ?? undefined,
    createdAt: new Date(row.created_at).getTime(),
  }
}

// Convert app QueueItem to DB insert format
function queueItemToDb(item: Omit<QueueItem, 'id' | 'createdAt' | 'status'>, userId: string) {
  return {
    user_id: userId,
    raw_content: item.rawContent,
    header: item.header,
    summary: item.summary,
    status: 'queued',
    source_url: item.sourceUrl ?? null,
    category: item.category ?? null,
    complexity_score: item.complexityScore ?? null,
    sequence_order: item.sequenceOrder ?? null,
  }
}

export function useQueue(): UseQueueReturn {
  const { user, isLoading: isAuthLoading, isConfigured } = useAuth()
  const [queue, setQueue] = useState<QueueItem[]>([])
  const [isLoading, setIsLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const migrationAttempted = useRef(false)

  // Determine storage mode
  const useSupabase = isConfigured && user !== null

  // Load from localStorage
  const loadFromLocalStorage = useCallback((): QueueItem[] => {
    try {
      const stored = localStorage.getItem(STORAGE_KEY)
      if (stored) {
        const parsed = JSON.parse(stored)
        if (Array.isArray(parsed)) {
          return parsed.filter((item: QueueItem) => item.status === 'queued')
        }
      }
    } catch (e) {
      console.error('Failed to load queue from localStorage:', e)
    }
    return []
  }, [])

  // Save to localStorage
  const saveToLocalStorage = useCallback((items: QueueItem[]) => {
    try {
      localStorage.setItem(STORAGE_KEY, JSON.stringify(items))
    } catch (e) {
      console.error('Failed to save queue to localStorage:', e)
    }
  }, [])

  // Migrate localStorage data to Supabase
  const migrateToSupabase = useCallback(async (userId: string) => {
    const migrationKey = `${MIGRATION_KEY}_${userId}`

    // Check if already migrated
    if (localStorage.getItem(migrationKey)) {
      return
    }

    const localItems = loadFromLocalStorage()
    if (localItems.length === 0) {
      localStorage.setItem(migrationKey, 'true')
      return
    }

    const supabase = createClient()
    if (!supabase) return

    try {
      // Insert all local items to Supabase
      const insertItems = localItems.map((item, index) => ({
        user_id: userId,
        raw_content: item.rawContent,
        header: item.header,
        summary: item.summary,
        status: item.status,
        source_url: item.sourceUrl ?? null,
        category: item.category ?? null,
        complexity_score: item.complexityScore ?? null,
        sequence_order: index,
      }))

      const { error } = await supabase.from('queue_items').insert(insertItems)

      if (error) {
        console.error('Migration error:', error)
        return
      }

      // Mark as migrated and clear localStorage
      localStorage.setItem(migrationKey, 'true')
      localStorage.removeItem(STORAGE_KEY)
      console.log(`Migrated ${localItems.length} queue items to Supabase`)
    } catch (e) {
      console.error('Migration failed:', e)
    }
  }, [loadFromLocalStorage])

  // Fetch from Supabase
  const fetchFromSupabase = useCallback(async () => {
    if (!user) return []

    const supabase = createClient()
    if (!supabase) return []

    const { data, error } = await supabase
      .from('queue_items')
      .select('*')
      .eq('user_id', user.id)
      .eq('status', 'queued')
      .order('sequence_order', { ascending: true, nullsFirst: false })
      .order('created_at', { ascending: true })

    if (error) {
      console.error('Fetch error:', error)
      throw new Error(error.message)
    }

    return (data || []).map(dbToQueueItem)
  }, [user])

  // Initial load and migration
  useEffect(() => {
    if (isAuthLoading) return

    const init = async () => {
      setIsLoading(true)
      setError(null)

      try {
        if (useSupabase && user) {
          // Attempt migration once per session
          if (!migrationAttempted.current) {
            migrationAttempted.current = true
            await migrateToSupabase(user.id)
          }

          const items = await fetchFromSupabase()
          setQueue(items)
        } else {
          // Use localStorage for unauthenticated users
          const items = loadFromLocalStorage()
          setQueue(items)
        }
      } catch (e) {
        setError(e instanceof Error ? e.message : 'Failed to load queue')
      } finally {
        setIsLoading(false)
      }
    }

    init()
  }, [isAuthLoading, useSupabase, user, fetchFromSupabase, loadFromLocalStorage, migrateToSupabase])

  // Sync localStorage changes for unauthenticated users
  useEffect(() => {
    if (!useSupabase && !isLoading) {
      saveToLocalStorage(queue)
    }
  }, [queue, useSupabase, isLoading, saveToLocalStorage])

  // Add item
  const addItem = useCallback(async (
    item: Omit<QueueItem, 'id' | 'createdAt' | 'status'>
  ): Promise<QueueItem | null> => {
    if (useSupabase && user) {
      const supabase = createClient()
      if (!supabase) return null

      const insertData = queueItemToDb(item, user.id)
      const { data, error } = await supabase
        .from('queue_items')
        .insert(insertData)
        .select()
        .single()

      if (error) {
        console.error('Add item error:', error)
        setError(error.message)
        return null
      }

      const newItem = dbToQueueItem(data)
      setQueue(prev => [...prev, newItem])
      return newItem
    } else {
      // localStorage mode
      const newItem: QueueItem = {
        ...item,
        id: crypto.randomUUID(),
        status: 'queued',
        createdAt: Date.now(),
      }
      setQueue(prev => [...prev, newItem])
      return newItem
    }
  }, [useSupabase, user])

  // Remove item
  const removeItem = useCallback(async (id: string): Promise<boolean> => {
    if (useSupabase && user) {
      const supabase = createClient()
      if (!supabase) return false

      const { error } = await supabase
        .from('queue_items')
        .delete()
        .eq('id', id)
        .eq('user_id', user.id)

      if (error) {
        console.error('Remove item error:', error)
        setError(error.message)
        return false
      }
    }

    setQueue(prev => prev.filter(item => item.id !== id))
    return true
  }, [useSupabase, user])

  // Update item
  const updateItem = useCallback(async (
    id: string,
    updates: Partial<QueueItem>
  ): Promise<boolean> => {
    if (useSupabase && user) {
      const supabase = createClient()
      if (!supabase) return false

      const dbUpdates: Record<string, unknown> = {}
      if (updates.rawContent !== undefined) dbUpdates.raw_content = updates.rawContent
      if (updates.header !== undefined) dbUpdates.header = updates.header
      if (updates.summary !== undefined) dbUpdates.summary = updates.summary
      if (updates.status !== undefined) dbUpdates.status = updates.status
      if (updates.sourceUrl !== undefined) dbUpdates.source_url = updates.sourceUrl
      if (updates.category !== undefined) dbUpdates.category = updates.category
      if (updates.complexityScore !== undefined) dbUpdates.complexity_score = updates.complexityScore
      if (updates.sequenceOrder !== undefined) dbUpdates.sequence_order = updates.sequenceOrder

      const { error } = await supabase
        .from('queue_items')
        .update(dbUpdates)
        .eq('id', id)
        .eq('user_id', user.id)

      if (error) {
        console.error('Update item error:', error)
        setError(error.message)
        return false
      }
    }

    setQueue(prev => prev.map(item =>
      item.id === id ? { ...item, ...updates } : item
    ))
    return true
  }, [useSupabase, user])

  // Reorder queue (for Curriculum Architect)
  const reorderQueue = useCallback(async (reorderedItems: QueueItem[]): Promise<boolean> => {
    if (useSupabase && user) {
      const supabase = createClient()
      if (!supabase) return false

      // Update sequence_order for all items in a transaction-like manner
      const updates = reorderedItems.map((item, index) =>
        supabase
          .from('queue_items')
          .update({ sequence_order: index })
          .eq('id', item.id)
          .eq('user_id', user.id)
      )

      const results = await Promise.all(updates)
      const hasError = results.some(r => r.error)

      if (hasError) {
        console.error('Reorder error')
        setError('Failed to reorder queue')
        return false
      }
    }

    setQueue(reorderedItems)
    return true
  }, [useSupabase, user])

  // Mark as learned (removes from queue and returns item for archiving)
  const markAsLearned = useCallback(async (id: string): Promise<QueueItem | null> => {
    const item = queue.find(q => q.id === id)
    if (!item) return null

    const removed = await removeItem(id)
    return removed ? item : null
  }, [queue, removeItem])

  // Refetch
  const refetch = useCallback(async () => {
    setIsLoading(true)
    setError(null)

    try {
      if (useSupabase && user) {
        const items = await fetchFromSupabase()
        setQueue(items)
      } else {
        const items = loadFromLocalStorage()
        setQueue(items)
      }
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Failed to refetch queue')
    } finally {
      setIsLoading(false)
    }
  }, [useSupabase, user, fetchFromSupabase, loadFromLocalStorage])

  return {
    queue,
    isLoading,
    error,
    addItem,
    removeItem,
    updateItem,
    reorderQueue,
    markAsLearned,
    refetch,
  }
}
```

---

### 3. useArchive Hook (`hooks/useArchive.ts`)

```typescript
// hooks/useArchive.ts
'use client'

import { useState, useEffect, useCallback, useRef } from 'react'
import { createClient } from '@/lib/supabase/client'
import { useAuth } from '@/context/AuthContext'
import { ArchiveItem, QueueItem } from '@/types'

const STORAGE_KEY = 'focus-first-history'
const MIGRATION_KEY = 'focus-first-history_migrated'
const MAX_ARCHIVE_ITEMS = 50

interface UseArchiveReturn {
  archive: ArchiveItem[]
  isLoading: boolean
  error: string | null
  addToArchive: (item: QueueItem) => Promise<ArchiveItem | null>
  removeFromArchive: (id: string) => Promise<boolean>
  refetch: () => Promise<void>
}

// Convert DB row to app ArchiveItem
function dbToArchiveItem(row: {
  id: string
  header: string
  summary: string
  source_url: string | null
  learned_at: string
}): ArchiveItem {
  return {
    id: row.id,
    header: row.header,
    summary: row.summary,
    sourceUrl: row.source_url,
    learnedAt: new Date(row.learned_at).getTime(),
  }
}

export function useArchive(): UseArchiveReturn {
  const { user, isLoading: isAuthLoading, isConfigured } = useAuth()
  const [archive, setArchive] = useState<ArchiveItem[]>([])
  const [isLoading, setIsLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const migrationAttempted = useRef(false)

  // Determine storage mode
  const useSupabase = isConfigured && user !== null

  // Load from localStorage
  const loadFromLocalStorage = useCallback((): ArchiveItem[] => {
    try {
      const stored = localStorage.getItem(STORAGE_KEY)
      if (stored) {
        const parsed = JSON.parse(stored)
        if (Array.isArray(parsed)) {
          return parsed
        }
      }
    } catch (e) {
      console.error('Failed to load archive from localStorage:', e)
    }
    return []
  }, [])

  // Save to localStorage
  const saveToLocalStorage = useCallback((items: ArchiveItem[]) => {
    try {
      localStorage.setItem(STORAGE_KEY, JSON.stringify(items))
    } catch (e) {
      console.error('Failed to save archive to localStorage:', e)
    }
  }, [])

  // Migrate localStorage data to Supabase
  const migrateToSupabase = useCallback(async (userId: string) => {
    const migrationKey = `${MIGRATION_KEY}_${userId}`

    // Check if already migrated
    if (localStorage.getItem(migrationKey)) {
      return
    }

    const localItems = loadFromLocalStorage()
    if (localItems.length === 0) {
      localStorage.setItem(migrationKey, 'true')
      return
    }

    const supabase = createClient()
    if (!supabase) return

    try {
      // Insert all local items to Supabase
      const insertItems = localItems.map(item => ({
        user_id: userId,
        header: item.header,
        summary: item.summary,
        source_url: item.sourceUrl ?? null,
        learned_at: new Date(item.learnedAt).toISOString(),
      }))

      const { error } = await supabase.from('archive_items').insert(insertItems)

      if (error) {
        console.error('Archive migration error:', error)
        return
      }

      // Mark as migrated and clear localStorage
      localStorage.setItem(migrationKey, 'true')
      localStorage.removeItem(STORAGE_KEY)
      console.log(`Migrated ${localItems.length} archive items to Supabase`)
    } catch (e) {
      console.error('Archive migration failed:', e)
    }
  }, [loadFromLocalStorage])

  // Fetch from Supabase
  const fetchFromSupabase = useCallback(async () => {
    if (!user) return []

    const supabase = createClient()
    if (!supabase) return []

    const { data, error } = await supabase
      .from('archive_items')
      .select('*')
      .eq('user_id', user.id)
      .order('learned_at', { ascending: false })
      .limit(MAX_ARCHIVE_ITEMS)

    if (error) {
      console.error('Archive fetch error:', error)
      throw new Error(error.message)
    }

    return (data || []).map(dbToArchiveItem)
  }, [user])

  // Initial load and migration
  useEffect(() => {
    if (isAuthLoading) return

    const init = async () => {
      setIsLoading(true)
      setError(null)

      try {
        if (useSupabase && user) {
          // Attempt migration once per session
          if (!migrationAttempted.current) {
            migrationAttempted.current = true
            await migrateToSupabase(user.id)
          }

          const items = await fetchFromSupabase()
          setArchive(items)
        } else {
          // Use localStorage for unauthenticated users
          const items = loadFromLocalStorage()
          setArchive(items)
        }
      } catch (e) {
        setError(e instanceof Error ? e.message : 'Failed to load archive')
      } finally {
        setIsLoading(false)
      }
    }

    init()
  }, [isAuthLoading, useSupabase, user, fetchFromSupabase, loadFromLocalStorage, migrateToSupabase])

  // Sync localStorage changes for unauthenticated users
  useEffect(() => {
    if (!useSupabase && !isLoading) {
      saveToLocalStorage(archive)
    }
  }, [archive, useSupabase, isLoading, saveToLocalStorage])

  // Add to archive (from a learned QueueItem)
  const addToArchive = useCallback(async (queueItem: QueueItem): Promise<ArchiveItem | null> => {
    const archiveItem: ArchiveItem = {
      id: queueItem.id,
      header: queueItem.header,
      summary: queueItem.summary,
      sourceUrl: queueItem.sourceUrl,
      learnedAt: Date.now(),
    }

    if (useSupabase && user) {
      const supabase = createClient()
      if (!supabase) return null

      const { data, error } = await supabase
        .from('archive_items')
        .insert({
          user_id: user.id,
          header: archiveItem.header,
          summary: archiveItem.summary,
          source_url: archiveItem.sourceUrl ?? null,
        })
        .select()
        .single()

      if (error) {
        console.error('Add to archive error:', error)
        setError(error.message)
        return null
      }

      const newItem = dbToArchiveItem(data)
      setArchive(prev => {
        const updated = [newItem, ...prev]
        return updated.slice(0, MAX_ARCHIVE_ITEMS)
      })
      return newItem
    } else {
      // localStorage mode
      setArchive(prev => {
        const updated = [archiveItem, ...prev]
        return updated.slice(0, MAX_ARCHIVE_ITEMS)
      })
      return archiveItem
    }
  }, [useSupabase, user])

  // Remove from archive
  const removeFromArchive = useCallback(async (id: string): Promise<boolean> => {
    if (useSupabase && user) {
      const supabase = createClient()
      if (!supabase) return false

      const { error } = await supabase
        .from('archive_items')
        .delete()
        .eq('id', id)
        .eq('user_id', user.id)

      if (error) {
        console.error('Remove from archive error:', error)
        setError(error.message)
        return false
      }
    }

    setArchive(prev => prev.filter(item => item.id !== id))
    return true
  }, [useSupabase, user])

  // Refetch
  const refetch = useCallback(async () => {
    setIsLoading(true)
    setError(null)

    try {
      if (useSupabase && user) {
        const items = await fetchFromSupabase()
        setArchive(items)
      } else {
        const items = loadFromLocalStorage()
        setArchive(items)
      }
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Failed to refetch archive')
    } finally {
      setIsLoading(false)
    }
  }, [useSupabase, user, fetchFromSupabase, loadFromLocalStorage])

  return {
    archive,
    isLoading,
    error,
    addToArchive,
    removeFromArchive,
    refetch,
  }
}
```

---

### 4. Modified page.tsx

```typescript
// app/page.tsx
'use client'

import { useState, useCallback, useRef, useEffect } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import DumpForm from '@/components/DumpForm'
import FocusCard from '@/components/FocusCard'
import ArchitectReasoning from '@/components/ArchitectReasoning'
import ArchiveDrawer from '@/components/ArchiveDrawer'
import AuthModal from '@/components/AuthModal'
import { useAuth } from '@/context/AuthContext'
import { useQueue } from '@/hooks/useQueue'
import { useArchive } from '@/hooks/useArchive'
import { QueueItem, ArchitectState, ArchitectResponse, ArchiveItem } from '@/types'

export default function Home() {
  const [isProcessing, setIsProcessing] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [isDumpExpanded, setIsDumpExpanded] = useState(false)
  const [isArchiveOpen, setIsArchiveOpen] = useState(false)
  const [isAuthModalOpen, setIsAuthModalOpen] = useState(false)

  const { user, isLoading: isAuthLoading, isConfigured: isAuthConfigured, signOut } = useAuth()

  // Use the new hooks for data management
  const {
    queue,
    isLoading: isQueueLoading,
    error: queueError,
    addItem,
    reorderQueue,
    markAsLearned,
  } = useQueue()

  const {
    archive,
    isLoading: isArchiveLoading,
    error: archiveError,
    addToArchive,
    removeFromArchive,
  } = useArchive()

  // Combined loading state
  const isLoaded = !isQueueLoading && !isArchiveLoading

  // Architect state
  const [architectState, setArchitectState] = useState<ArchitectState>({
    isAnalyzing: false,
    reasoning: null
  })

  // Debounce ref for architect analysis
  const architectTimeoutRef = useRef<NodeJS.Timeout | null>(null)

  // Collapse dump form when queue has items
  useEffect(() => {
    if (queue.length > 0 && isDumpExpanded) {
      setIsDumpExpanded(false)
    }
  }, [queue.length, isDumpExpanded])

  // Analyze and reorder queue using Curriculum Architect
  const analyzeAndReorderQueue = useCallback(async (
    currentQueue: QueueItem[],
    trigger: 'item_added' | 'item_learned'
  ) => {
    // Skip for single item or empty queues
    if (currentQueue.length <= 1) return

    setArchitectState(prev => ({ ...prev, isAnalyzing: true, reasoning: null }))

    try {
      const response = await fetch('/api/architect', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          queue: currentQueue.map(item => ({
            id: item.id,
            header: item.header,
            summary: item.summary,
            category: item.category,
            complexityScore: item.complexityScore
          })),
          trigger
        })
      })

      if (!response.ok) {
        throw new Error('Analysis failed')
      }

      const data: ArchitectResponse = await response.json()

      if (data.analysisMetadata.reorderOccurred) {
        await reorderQueue(data.reorderedQueue)
      }

      setArchitectState(prev => ({
        ...prev,
        isAnalyzing: false,
        reasoning: data.reasoning
      }))
    } catch (error) {
      console.error('Architect analysis failed:', error)
      setArchitectState(prev => ({ ...prev, isAnalyzing: false }))
    }
  }, [reorderQueue])

  // Schedule architect analysis with debounce
  const scheduleArchitectAnalysis = useCallback((
    currentQueue: QueueItem[],
    trigger: 'item_added' | 'item_learned'
  ) => {
    if (architectTimeoutRef.current) {
      clearTimeout(architectTimeoutRef.current)
    }

    architectTimeoutRef.current = setTimeout(() => {
      analyzeAndReorderQueue(currentQueue, trigger)
    }, 500)
  }, [analyzeAndReorderQueue])

  const handleSubmit = useCallback(async (input: string) => {
    setIsProcessing(true)
    setError(null)

    try {
      const response = await fetch('/api/summarize', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ input }),
      })

      if (!response.ok) {
        const errorData = await response.json()
        throw new Error(errorData.error || 'Failed to process input')
      }

      const data = await response.json()

      // Add item using the hook
      const newItem = await addItem({
        rawContent: input,
        header: data.header,
        summary: data.summary,
        sourceUrl: data.sourceUrl,
      })

      if (newItem) {
        // Schedule architect analysis with updated queue
        const newQueue = [...queue, newItem]
        scheduleArchitectAnalysis(newQueue, 'item_added')
      }

      setIsDumpExpanded(false)
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Something went wrong')
    } finally {
      setIsProcessing(false)
    }
  }, [addItem, queue, scheduleArchitectAnalysis])

  const handleMarkLearned = useCallback(async () => {
    const currentItem = queue[0]
    if (!currentItem) return

    // Mark as learned in queue (removes it)
    const learnedItem = await markAsLearned(currentItem.id)

    if (learnedItem) {
      // Add to archive
      await addToArchive(learnedItem)

      // Trigger architect analysis if more than 1 item remains
      const newQueue = queue.slice(1)
      if (newQueue.length > 1) {
        setTimeout(() => {
          scheduleArchitectAnalysis(newQueue, 'item_learned')
        }, 300)
      }
    }
  }, [queue, markAsLearned, addToArchive, scheduleArchitectAnalysis])

  const handleRequeue = useCallback(async (item: ArchiveItem) => {
    // Remove from archive
    const removed = await removeFromArchive(item.id)
    if (!removed) return

    // Add back to queue as a new item
    const requeuedItem = await addItem({
      rawContent: item.header,
      header: item.header,
      summary: item.summary,
      sourceUrl: item.sourceUrl,
    })

    if (requeuedItem) {
      const newQueue = [...queue, requeuedItem]
      scheduleArchitectAnalysis(newQueue, 'item_added')
    }

    // Close archive drawer
    setIsArchiveOpen(false)
  }, [removeFromArchive, addItem, queue, scheduleArchitectAnalysis])

  const toggleArchive = useCallback(() => {
    setIsArchiveOpen((prev) => !prev)
  }, [])

  const toggleDump = useCallback(() => {
    setIsDumpExpanded((prev) => !prev)
  }, [])

  // Show loading state
  if (!isLoaded) {
    return (
      <div className="flex items-center justify-center min-h-[400px]">
        <div className="text-faded text-sm animate-pulse">Loading...</div>
      </div>
    )
  }

  // Show hook errors
  const displayError = error || queueError || archiveError

  const currentItem = queue[0]
  const remainingCount = queue.length - 1

  return (
    <div className="space-y-6">
      {/* Header with Auth and Archive */}
      <div className="flex justify-between items-center">
        {/* Auth Controls - only show when Supabase is configured */}
        <div className="text-xs">
          {isAuthConfigured ? (
            isAuthLoading ? (
              <span className="text-faded animate-pulse">...</span>
            ) : user ? (
              <div className="flex items-center gap-3">
                <span className="text-faded">{user.email}</span>
                <button
                  onClick={() => signOut()}
                  className="text-faded hover:text-ink transition-colors underline underline-offset-2"
                >
                  Sign out
                </button>
              </div>
            ) : (
              <button
                onClick={() => setIsAuthModalOpen(true)}
                className="text-faded hover:text-ink transition-colors underline underline-offset-2"
              >
                Sign in to sync
              </button>
            )
          ) : null}
        </div>

        {/* Archive Toggle */}
        <button
          onClick={toggleArchive}
          className="text-xs text-faded hover:text-ink transition-colors underline underline-offset-2"
        >
          Archive {archive.length > 0 && `(${archive.length})`}
        </button>
      </div>

      {/* Error Display */}
      {displayError && (
        <div className="border-2 border-ink bg-paper p-4 text-center rounded-lg">
          <p className="text-sm text-ink">{displayError}</p>
          <button
            onClick={() => setError(null)}
            className="mt-2 text-xs text-faded underline hover:text-ink"
          >
            Dismiss
          </button>
        </div>
      )}

      {/* Dump Form - collapsible when queue has items */}
      {queue.length > 0 ? (
        <DumpForm
          onSubmit={handleSubmit}
          isProcessing={isProcessing}
          isCollapsed={!isDumpExpanded}
          onToggle={toggleDump}
        />
      ) : (
        <DumpForm
          onSubmit={handleSubmit}
          isProcessing={isProcessing}
          isCollapsed={false}
          onToggle={() => {}}
        />
      )}

      {/* Architect Reasoning Display */}
      <ArchitectReasoning
        reasoning={architectState.reasoning}
        isAnalyzing={architectState.isAnalyzing}
      />

      {/* Focus Card or Empty State with Animation */}
      <AnimatePresence mode="wait">
        {currentItem ? (
          <motion.div
            key={currentItem.id}
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0, y: -20 }}
            transition={{ duration: 0.3 }}
          >
            <FocusCard item={currentItem} onMarkLearned={handleMarkLearned} />
          </motion.div>
        ) : (
          <motion.div
            key="empty"
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            className="border-2 border-ink bg-paper p-8 text-center rounded-lg"
          >
            <p className="text-faded">All clear. Stay focused.</p>
          </motion.div>
        )}
      </AnimatePresence>

      {/* Queue Count */}
      {remainingCount > 0 && (
        <motion.p
          key={remainingCount}
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          className="text-center text-xs text-faded"
        >
          {remainingCount} more in signal
        </motion.p>
      )}

      {/* Archive Drawer */}
      <ArchiveDrawer
        isOpen={isArchiveOpen}
        onClose={() => setIsArchiveOpen(false)}
        items={archive}
        onRequeue={handleRequeue}
      />

      {/* Auth Modal */}
      <AuthModal
        isOpen={isAuthModalOpen}
        onClose={() => setIsAuthModalOpen(false)}
      />
    </div>
  )
}
```

---

## 5. Migration Strategy

### How Migration Works

1. **Per-user migration tracking**: Migration is tracked per user via localStorage key `signal_queue_migrated_{userId}` and `focus-first-history_migrated_{userId}`

2. **Migration triggers on first login**:
   - When a user logs in, the hooks check if migration has occurred
   - If not, they read from localStorage, insert into Supabase, then mark as migrated
   - localStorage is cleared after successful migration

3. **Idempotent migration**:
   - The migration key prevents duplicate migrations
   - If migration fails, localStorage data is preserved

4. **No data loss**:
   - localStorage is only cleared after successful Supabase insert
   - Users can always fall back to localStorage if not logged in

---

## 6. Handling Unauthenticated Users

### Strategy: Graceful Degradation

1. **When user is not logged in**:
   - Hooks detect `user === null`
   - All operations fall back to localStorage
   - App functions identically to Phase 1

2. **Sign-in prompt (optional)**:
   - Changed "Sign in" button text to "Sign in to sync"
   - Provides gentle nudge without blocking functionality

3. **When user logs in**:
   - Automatic migration of localStorage data
   - Seamless transition to Supabase storage
   - User sees same data they had before

4. **When user logs out**:
   - Hooks switch back to localStorage mode
   - New data goes to localStorage
   - Previous Supabase data remains in cloud for next login

---

## File Structure Summary

```
focused-information/
├── hooks/
│   ├── useQueue.ts      # NEW - Queue CRUD operations
│   └── useArchive.ts    # NEW - Archive CRUD operations
├── types/
│   ├── index.ts         # EXISTING - No changes needed
│   └── database.ts      # NEW - Supabase types (optional but recommended)
├── app/
│   └── page.tsx         # MODIFIED - Use hooks instead of direct localStorage
└── lib/
    └── supabase/
        └── client.ts    # EXISTING - No changes needed
```

---

## Implementation Order

1. Create `hooks/` directory
2. Implement `hooks/useQueue.ts`
3. Implement `hooks/useArchive.ts`
4. Modify `app/page.tsx` to use hooks
5. Test locally with localStorage (no Supabase user)
6. Test with logged-in user (Supabase mode)
7. Test migration by having localStorage data then logging in
8. Verify RLS policies work correctly

---

## Edge Cases Handled

1. **Supabase not configured**: Falls back to localStorage seamlessly
2. **User logs out mid-session**: Switches to localStorage mode
3. **Network failure during Supabase operation**: Error state shown, localStorage preserved
4. **Duplicate migration attempts**: Migration key prevents duplicates
5. **Empty localStorage**: Migration marked as complete without insert
6. **Race conditions**: useRef for migration flag prevents multiple migration attempts

---

## Testing Checklist

- [ ] Unauthenticated user can add/remove/learn items (localStorage)
- [ ] Authenticated user can add/remove/learn items (Supabase)
- [ ] Migration works when user first logs in with existing localStorage data
- [ ] User logging out switches to localStorage mode
- [ ] User logging back in sees their Supabase data
- [ ] Architect reordering works with Supabase
- [ ] Archive drawer shows correct items
- [ ] Requeue from archive works
- [ ] RLS policies prevent access to other users' data
- [ ] Error states are displayed correctly
