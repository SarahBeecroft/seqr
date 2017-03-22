/* eslint-disable no-multi-spaces */

export const SHOW_ALL = 'ALL'
export const SHOW_ACCEPTED = 'ACCEPTED'
export const SHOW_NOT_ACCEPTED = 'NOT_ACCEPTED'
export const SHOW_IN_REVIEW = 'IN_REVIEW'
export const SHOW_UNCERTAIN = 'UNCERTAIN'
export const SHOW_HOLD = 'HOLD'
export const SHOW_MORE_INFO_NEEDED = 'MORE_INFO_NEEDED'

export const SORT_BY_FAMILY_NAME = 'FAMILY_NAME'
export const SORT_BY_DATE_ADDED = 'DATE_ADDED'
export const SORT_BY_DATE_LAST_CHANGED = 'DATE_LAST_CHANGED'

export const CASE_REVIEW_STATUS_IN_REVIEW = 'I'
export const CASE_REVIEW_STATUS_UNCERTAIN = 'U'
export const CASE_REVIEW_STATUS_ACCEPTED_PLATFORM_UNCERTAIN = 'A'
export const CASE_REVIEW_STATUS_ACCEPTED_EXOME = 'E'
export const CASE_REVIEW_STATUS_ACCEPTED_GENOME = 'G'
export const CASE_REVIEW_STATUS_ACCEPTED_RNASEQ = '3'
export const CASE_REVIEW_STATUS_NOT_ACCEPTED = 'R'
export const CASE_REVIEW_STATUS_HOLD = 'H'
export const CASE_REVIEW_STATUS_MORE_INFO_NEEDED = 'Q'

export const CASE_REVIEW_STATUS_OPTIONS = [
  { value: CASE_REVIEW_STATUS_IN_REVIEW,                   name: 'In Review',         color: '#2196F3' },
  { value: CASE_REVIEW_STATUS_UNCERTAIN,                   name: 'Uncertain',         color: '#FDDD1A' },
  { value: CASE_REVIEW_STATUS_ACCEPTED_PLATFORM_UNCERTAIN, name: 'Accepted: Platform Uncertain', color: 'orange' },
  { value: CASE_REVIEW_STATUS_ACCEPTED_EXOME,              name: 'Accepted: Exome',   color: '#8BC34A' },  //#673AB7
  { value: CASE_REVIEW_STATUS_ACCEPTED_GENOME,             name: 'Accepted: Genome',  color: '#8BC34A' },  //#FFC107
  { value: CASE_REVIEW_STATUS_ACCEPTED_RNASEQ,             name: 'Accepted: RNA-seq', color: '#8BC34A' },
  { value: CASE_REVIEW_STATUS_NOT_ACCEPTED,                name: 'Not Accepted',      color: '#F44336' },  //C5CAE9
  { value: CASE_REVIEW_STATUS_HOLD,                        name: 'Hold',              color: 'brown'   },
  { value: CASE_REVIEW_STATUS_MORE_INFO_NEEDED,            name: 'More Info Needed',  color: 'purple'   },
]

export const CASE_REVIEW_STATUS_NAME_LOOKUP = CASE_REVIEW_STATUS_OPTIONS.reduce(
  (acc, opt) => ({ ...acc,  ...{ [opt.value]: opt.text } }),
  {},
)