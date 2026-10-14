import type { IconName } from '@/components/ui/icons'
import type { ChatMode } from '@/types/chat'

export const APP_NAME = 'Amtsweg'
export const APP_TAGLINE = 'Your public services assistant'
export const APP_DISCLAIMER = 'Hackathon prototype. Not an official service of the Republic of Austria.'

// Placeholder until auth (ID Austria) exists.
export const USER_NAME = 'Armando'

export interface ModeOption {
  value: ChatMode
  label: string
  icon: IconName
  placeholder: string
  hint: string
}

export const MODES: ModeOption[] = [
  {
    value: 'ask',
    label: 'Ask',
    icon: 'search',
    placeholder: 'Ask about any Austrian public service...',
    hint: 'Answers can be inaccurate. Always check official sources such as oesterreich.gv.at.',
  },
  {
    value: 'task',
    label: 'Get it done',
    icon: 'clipboard-check',
    placeholder: 'Tell me what to take care of, e.g. "register my new address"...',
    hint: 'Nothing is submitted until you press "Sign & apply". It signs with your ID Austria.',
  },
]

export interface Topic {
  label: string
  icon: IconName
  prompt: string
}

// Common life events in Austria, from a citizen's point of view.
export const TOPICS: Topic[] = [
  { label: 'Student visa', icon: 'id-card', prompt: 'How do I renew my student visa?' },
  { label: 'Moving', icon: 'house', prompt: 'I moved. Please register my new main residence (Meldezettel).' },
  { label: 'New baby', icon: 'users', prompt: 'We had a baby. Apply for Familienbeihilfe and Kinderbetreuungsgeld for me.' },
  { label: 'Passport & ID', icon: 'id-card', prompt: 'My Reisepass expires soon. Help me renew it.' },
  { label: 'Taxes', icon: 'euro', prompt: 'File my Arbeitnehmerveranlagung on FinanzOnline.' },
  { label: 'Car', icon: 'car', prompt: 'I moved. What do I need to change on my car registration (Zulassung)?' },
  { label: 'Health', icon: 'heart', prompt: 'I lost my e-card. How do I get a replacement?' },
]
