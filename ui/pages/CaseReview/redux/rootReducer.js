import { combineReducers } from 'redux'
import { createSingleObjectReducer } from 'shared/utils/redux/reducerUtils'
import {
  immutableUserState,
  immutableProjectState,
  familiesByGuidState,
  individualsByGuidState,
} from 'shared/utils/redux/commonDataActionsAndSelectors'
import { pedigreeImageZoomModalState } from 'shared/components/panel/view-pedigree-image/zoom-modal/PedigreeImageZoomModal-redux'
import { phenotipsModalState } from 'shared/components/panel/view-phenotips-info/phenotips-modal/PhenotipsModal-redux'
import { richTextEditorModalState } from 'shared/components/modal/text-editor-modal/RichTextEditorModal-redux'

import { SHOW_ALL, SORT_BY_FAMILY_NAME } from '../constants'

// action creators and reducers in one file as suggested by https://github.com/erikras/ducks-modular-redux

// caseReviewTableState -  reducer, actions, and selectors
const UPDATE_CASE_REVIEW_TABLE_STATE = 'UPDATE_CASE_REVIEW_TABLE_STATE'

const caseReviewTableState = {
  caseReviewTableState: createSingleObjectReducer(UPDATE_CASE_REVIEW_TABLE_STATE, {
    familiesFilter: SHOW_ALL,
    familiesSortOrder: SORT_BY_FAMILY_NAME,
    familiesSortDirection: 1,
    showDetails: true,
  }, true),
}

export const updateFamiliesFilter = familiesFilter => ({ type: UPDATE_CASE_REVIEW_TABLE_STATE, updates: { familiesFilter } })
export const updateFamiliesSortOrder = familiesSortOrder => ({ type: UPDATE_CASE_REVIEW_TABLE_STATE, updates: { familiesSortOrder } })
export const updateFamiliesSortDirection = familiesSortDirection => ({ type: UPDATE_CASE_REVIEW_TABLE_STATE, updates: { familiesSortDirection } })
export const updateShowDetails = showDetails => ({ type: UPDATE_CASE_REVIEW_TABLE_STATE, updates: { showDetails } })

export const getCaseReviewTableState = state => state.caseReviewTableState

export const getFamiliesFilter = state => state.caseReviewTableState.familiesFilter
export const getFamiliesSortOrder = state => state.caseReviewTableState.familiesSortOrder
export const getFamiliesSortDirection = state => state.caseReviewTableState.familiesSortDirection
export const getShowDetails = state => state.caseReviewTableState.showDetails


// root reducer
const rootReducer = combineReducers({
  ...immutableUserState,
  ...immutableProjectState,
  ...familiesByGuidState,
  ...individualsByGuidState,
  ...caseReviewTableState,
  ...pedigreeImageZoomModalState,
  ...phenotipsModalState,
  ...richTextEditorModalState,
})

export default rootReducer


/**
 * Returns the sections of state to save in local storage in the browser.
 *
 * @param state The full redux state object.
 *
 * @returns A copy of state with restoredState applied
 */
export const getStateToSave = state => getCaseReviewTableState(state)

/**
 * Applies state to save in local storage in the browser.
 *
 * @param state The full redux state object.
 * @param restoredState Sections of state that have been restored from local storage.
 * @returns A copy of state with restoredState applied
 */
export const applyRestoredState = (state, restoredState) => {
  const result = { ...state, caseReviewTableState: restoredState }
  console.log('with restored state:\n  ', result)
  return result
}