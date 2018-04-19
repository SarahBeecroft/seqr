import { combineReducers } from 'redux'
import { reducer as formReducer, SubmissionError } from 'redux-form'

import { reducers as dashboardReducers } from 'pages/Dashboard/reducers'
import { reducers as projectReducers } from 'pages/Project/reducers'
import { HttpRequestHelper } from 'shared/utils/httpRequestHelper'
import { createObjectsByIdReducer, loadingReducer, zeroActionsReducer } from './utils/reducerFactories'
import modalReducers from './utils/modalReducer'

/**
 * Action creator and reducers in one file as suggested by https://github.com/erikras/ducks-modular-redux
 */

// actions
export const REQUEST_PROJECTS = 'REQUEST_PROJECTS'
export const RECEIVE_PROJECTS = 'RECEIVE_PROJECTS'
export const UPDATE_PROJECT_CATEGORIES_BY_GUID = 'UPDATE_PROJECT_CATEGORIES_BY_GUID'
export const RECEIVE_FAMILIES = 'RECEIVE_FAMILIES'
export const RECEIVE_INDIVIDUALS = 'RECEIVE_INDIVIDUALS'
export const RECEIVE_SAMPLES = 'RECEIVE_SAMPLES'
export const RECEIVE_DATASETS = 'RECEIVE_DATASETS'
export const REQUEST_GENES = 'REQUEST_GENES'
export const RECEIVE_GENES = 'RECEIVE_GENES'

// action creators
export const fetchProjects = () => {
  return (dispatch) => {
    dispatch({ type: REQUEST_PROJECTS })
    new HttpRequestHelper('/api/dashboard',
      (responseJson) => {
        dispatch({ type: UPDATE_PROJECT_CATEGORIES_BY_GUID, updatesById: responseJson.projectCategoriesByGuid })
        dispatch({ type: RECEIVE_PROJECTS, updatesById: responseJson.projectsByGuid })
      },
      e => dispatch({ type: RECEIVE_PROJECTS, error: e.message, updatesById: {} }),
    ).get()
  }
}


/**
 * POSTS a request to update the specified project and dispatches the appropriate events when the request finishes
 * Accepts a values object that includes any data to be posted as well as the following keys:
 *
 * action: A string representation of the action to perform. Can be "create", "update" or "delete". Defaults to "update"
 * projectGuid: The GUID for the project to update. If omitted, the action will be set to "create"
 * projectField: A specific field to update (e.g. "categories"). Should be used for fields which have special server-side logic for updating
 */
export const updateProject = (values) => {
  return (dispatch) => {
    const urlPath = values.projectGuid ? `/api/project/${values.projectGuid}` : '/api/project'
    const projectField = values.projectField ? `_${values.projectField}` : ''
    let action = 'create'
    if (values.projectGuid) {
      action = values.delete ? 'delete' : 'update'
    }

    return new HttpRequestHelper(`${urlPath}/${action}_project${projectField}`,
      (responseJson) => {
        if (responseJson.projectCategoriesByGuid) {
          dispatch({ type: UPDATE_PROJECT_CATEGORIES_BY_GUID, updatesById: responseJson.projectCategoriesByGuid })
        }
        dispatch({ type: RECEIVE_PROJECTS, updatesById: responseJson.projectsByGuid })
      },
      (e) => { throw new SubmissionError({ _error: [e.message] }) },
    ).post(values)
  }
}

export const updateFamilies = (values) => {
  return (dispatch, getState) => {
    const action = values.delete ? 'delete' : 'edit'
    return new HttpRequestHelper(`/api/project/${getState().currentProjectGuid}/${action}_families`,
      (responseJson) => {
        dispatch({ type: RECEIVE_FAMILIES, updatesById: responseJson.familiesByGuid })
      },
      (e) => { throw new SubmissionError({ _error: [e.message] }) },
    ).post(values)
  }
}

export const updateIndividuals = (values) => {
  return (dispatch, getState) => {
    let action = 'edit_individuals'
    if (values.uploadedFileId) {
      action = `save_individuals_table/${values.uploadedFileId}`
    } else if (values.delete) {
      action = 'delete_individuals'
    }

    return new HttpRequestHelper(`/api/project/${getState().currentProjectGuid}/${action}`,
      (responseJson) => {
        dispatch({ type: RECEIVE_INDIVIDUALS, updatesById: responseJson.individualsByGuid })
        dispatch({ type: RECEIVE_FAMILIES, updatesById: responseJson.familiesByGuid })
      },
      (e) => {
        if (e.body && e.body.errors) {
          throw new SubmissionError({ _error: e.body.errors })
          // e.body.warnings.forEach((err) => { throw new SubmissionError({ _warning: err }) })
        } else {
          throw new SubmissionError({ _error: [e.message] })
        }
      },
    ).post(values)
  }
}

export const updateIndividual = (individualGuid, values) => {
  return (dispatch) => {
    return new HttpRequestHelper(`/api/individual/${individualGuid}/update`,
      (responseJson) => {
        dispatch({ type: RECEIVE_INDIVIDUALS, updatesById: responseJson })
      },
      (e) => {
        throw new SubmissionError({ _error: [e.message] })
      },
    ).post(values)
  }
}

export const loadGene = (geneId) => {
  return (dispatch, getState) => {
    if (!getState().genesById[geneId]) {
      dispatch({ type: REQUEST_GENES })
      // TODO use a new gene info endpoint, this is the xbrowse one
      new HttpRequestHelper(`/api/gene-info/${geneId}`,
        (responseJson) => {
          dispatch({ type: RECEIVE_GENES, updatesById: { [geneId]: responseJson.gene } })
        },
        (e) => {
          dispatch({ type: RECEIVE_GENES, error: e.message, updatesById: {} })
        },
      ).get()
    }
  }
}

export const updateGeneNote = () => {
  // TODO actually implement this
  return (dispatch) => {
    return new HttpRequestHelper('/api/gene-info/0',
      (responseJson) => {
        console.log(responseJson)
        dispatch({ type: RECEIVE_GENES, updatesById: { } })
      },
      (e) => {
        dispatch({ type: RECEIVE_GENES, error: e.message, updatesById: {} })
        throw new SubmissionError({ _error: [e.message] })
      },
    ).get()
  }
}


// root reducer
const rootReducer = combineReducers(Object.assign({
  projectCategoriesByGuid: createObjectsByIdReducer(UPDATE_PROJECT_CATEGORIES_BY_GUID),
  projectsByGuid: createObjectsByIdReducer(RECEIVE_PROJECTS),
  projectsLoading: loadingReducer(REQUEST_PROJECTS, RECEIVE_PROJECTS),
  familiesByGuid: createObjectsByIdReducer(RECEIVE_FAMILIES),
  individualsByGuid: createObjectsByIdReducer(RECEIVE_INDIVIDUALS),
  datasetsByGuid: createObjectsByIdReducer(RECEIVE_DATASETS),
  samplesByGuid: createObjectsByIdReducer(RECEIVE_SAMPLES),
  genesById: createObjectsByIdReducer(RECEIVE_GENES),
  genesLoading: loadingReducer(REQUEST_GENES, RECEIVE_GENES),
  user: zeroActionsReducer,
  form: formReducer,
}, modalReducers, dashboardReducers, projectReducers))

export default rootReducer

// basic selectors
export const getProjectsIsLoading = state => state.projectsLoading.isLoading
export const getProjectsByGuid = state => state.projectsByGuid
export const getProjectCategoriesByGuid = state => state.projectCategoriesByGuid
export const getFamiliesByGuid = state => state.familiesByGuid
export const getIndividualsByGuid = state => state.individualsByGuid
export const getGenesById = state => state.genesById
export const getGenesIsLoading = state => state.genesLoading.isLoading
export const getUser = state => state.user
