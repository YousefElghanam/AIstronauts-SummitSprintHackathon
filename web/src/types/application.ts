import type { ChatAttachment } from './chat'

export interface FormField {
  id: string
  label: string
  type: 'text' | 'date' | 'email'
  value: string
  // Filled from the user's ID Austria profile (read-only).
  fromIdAustria?: boolean
}

export interface FormDocument {
  id: string
  label: string
  file?: ChatAttachment
}

export interface ApplicationForm {
  id: string
  title: string
  authority: string
  fields: FormField[]
  documents: FormDocument[]
  status: 'draft' | 'submitting' | 'submitted'
  reference?: string
}
