import type { ApplicationForm } from '@/types/application'
import { createId } from '@/utils/id'
import { ID_AUSTRIA_PROFILE } from './idAustria'

// Use case: student visa renewal (Aufenthaltsbewilligung "Student")

export const PATTERN = /visa|permit|residence|aufenthalt|studier|student|ma ?35/i

export const PREPARE_PROMPT = 'Prepare my application for me'

export const PROCESS = `Here's how to renew your student residence permit (Aufenthaltsbewilligung "Student"):

1. Apply in time
You can apply up to 3 months before your permit expires, and at the latest before it expires. If you apply in time, you may stay in Austria while your application is processed.

2. Prepare your documents
• Renewal application form (Verlängerungsantrag)
• Valid passport and a recent passport photo
• Confirmation of enrolment for the current semester
• Proof of study success from the last academic year
• Proof of health insurance
• Proof of accommodation (e.g. rental contract)
• Proof of sufficient funds

3. Submit in person
Go to the residence authority where you live: MA 35 in Vienna, otherwise your Bezirkshauptmannschaft or Magistrat. Your photo and fingerprints are taken for the new card.

4. Pay the fee and collect your new card
You'll be told when your card is ready to pick up.

Source: migration.gv.at. Always check the latest requirements there.`

export const FOLLOW_UPS: Record<string, string> = {
  'What counts as study success?':
    'You need passed exams worth at least 16 ECTS (or 8 semester hours) from the previous academic year. ' +
    'Ask your university for a "Studienerfolgsnachweis". Most universities let you download it from the student portal.',
  'How much money do I need to show?':
    'You need to show you can cover your living costs for the coming year. The monthly amount is set every year ' +
    'and is lower if you are under 24. A bank statement, a scholarship letter or a sponsor\'s declaration of liability ' +
    '(Haftungserklärung) are accepted. Check the current amounts on migration.gv.at.',
  'Where do I submit it in Vienna?':
    'In Vienna it\'s MA 35 (Einwanderung und Staatsbürgerschaft). Book an appointment in advance and bring all ' +
    'original documents plus copies.',
}

export const ASK_SUGGESTIONS = [PREPARE_PROMPT, ...Object.keys(FOLLOW_UPS)]

export const FORM_INTRO =
  'I\'ve prepared your application to renew your student residence permit. Your personal details are filled in ' +
  'from your ID Austria. Please complete the rest and attach the documents below. When everything is ready, ' +
  'press "Sign & apply".'

export function createForm(): ApplicationForm {
  const p = ID_AUSTRIA_PROFILE
  return {
    id: createId(),
    title: 'Renewal of residence permit "Student"',
    authority: 'MA 35, Vienna',
    status: 'draft',
    fields: [
      { id: 'fullName', label: 'Full name', type: 'text', value: p.fullName, fromIdAustria: true },
      { id: 'dateOfBirth', label: 'Date of birth', type: 'date', value: p.dateOfBirth, fromIdAustria: true },
      { id: 'nationality', label: 'Nationality', type: 'text', value: p.nationality, fromIdAustria: true },
      { id: 'passportNumber', label: 'Passport number', type: 'text', value: p.passportNumber, fromIdAustria: true },
      { id: 'address', label: 'Main residence', type: 'text', value: p.address, fromIdAustria: true },
      { id: 'email', label: 'Email', type: 'email', value: p.email, fromIdAustria: true },
      { id: 'permitNumber', label: 'Current permit number', type: 'text', value: '' },
      { id: 'permitExpiry', label: 'Current permit valid until', type: 'date', value: '' },
      { id: 'university', label: 'University', type: 'text', value: '' },
      { id: 'studyProgramme', label: 'Study programme', type: 'text', value: '' },
    ],
    documents: [
      { id: 'photo', label: 'Passport photo' },
      { id: 'enrolment', label: 'Confirmation of enrolment' },
      { id: 'studySuccess', label: 'Proof of study success' },
      { id: 'insurance', label: 'Proof of health insurance' },
      { id: 'accommodation', label: 'Proof of accommodation' },
      { id: 'funds', label: 'Proof of sufficient funds' },
    ],
  }
}

export function submittedReply(form: ApplicationForm, reference: string): string {
  const email = form.fields.find((f) => f.id === 'email')?.value ?? 'your email'
  return `Done! Your application was signed with your ID Austria and submitted to ${form.authority}.

Reference number: ${reference}
A confirmation was sent to ${email}.

What happens next:
• MA 35 checks your application and contacts you if anything is missing.
• You'll be invited to an appointment to have your photo and fingerprints taken for the new card.
• Since you applied before your permit expires, you may stay in Austria while it is processed.`
}
