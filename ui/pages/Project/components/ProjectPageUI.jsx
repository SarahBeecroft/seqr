import React from 'react'
import PropTypes from 'prop-types'
import { connect } from 'react-redux'
import { Grid, Loader } from 'semantic-ui-react'
import DocumentTitle from 'react-document-title'

import SectionHeader from 'shared/components/SectionHeader'
import { VerticalSpacer } from 'shared/components/Spacers'
import { getProject, getProjectDetailsIsLoading } from 'redux/rootReducer'
import { getShowDetails } from '../reducers'
import { getAnalysisStatusCounts } from '../utils/selectors'
import ProjectOverview from './ProjectOverview'
import VariantTags from './VariantTags'
import ProjectCollaborators from './ProjectCollaborators'
import GeneLists from './GeneLists'
import FamilyTable from './FamilyTable/FamilyTable'
import { DESCRIPTION, ANALYSIS_STATUS, ANALYSED_BY, ANALYSIS_NOTES, ANALYSIS_SUMMARY } from './FamilyTable/FamilyRow'


/**
Add charts:
- variant tags - how many families have particular tags
- analysis status
 Phenotypes:
   Cardio - 32 individuals
   Eye - 10 individuals
   Ear - 5 inidividuals
   Neuro - 10 individuals
   Other - 5 individuals

 Data:
    Exome - HaplotypeCaller variant calls (32 samples), read viz (10 samples)
    Whole Genome - HaplotypeCaller variant calls (32 samples), Manta SV calls (10 samples), read data (5 samples)
    RNA - HaplotypeCaller variant calls (32 samples)

Phenotypes:
- how many families have phenotype terms in each category

What's new:
 - variant tags

*/

const ProjectSectionComponent = ({ loading, label, children, editPath, linkPath, linkText, project }) => {
  return ([
    <SectionHeader key="header">{label}</SectionHeader>,
    <div key="content">
      {loading ? <Loader key="content" inline active /> : children}
    </div>,
    editPath && project.canEdit ? (
      <a key="edit" href={`/project/${project.deprecatedProjectId}/${editPath}`}>
        {`Edit ${label}`}
      </a>
    ) : null,
    linkText ? (
      <div key="link" style={{ paddingTop: '15px', paddingLeft: '35px' }}>
        <a href={`/project/${project.deprecatedProjectId}/${linkPath}`}>{linkText}</a>
      </div>
    ) : null,
  ])
}

const mapSectionStateToProps = state => ({
  project: getProject(state),
  loading: getProjectDetailsIsLoading(state),
})

const ProjectSection = connect(mapSectionStateToProps)(ProjectSectionComponent)


const ProjectPageUI = props =>
  <div>
    <DocumentTitle title={`seqr: ${props.project.name}`} />
    <Grid stackable style={{ margin: '0px', padding: '0px' }}>
      <Grid.Row style={{ padding: '0px' }}>
        <Grid.Column width={4} style={{ margin: '0px', padding: '0px' }}>
          <ProjectSection label="Overview">
            <ProjectOverview />
          </ProjectSection>
        </Grid.Column>
      </Grid.Row>
      <Grid.Row>
        <Grid.Column width={12} style={{ paddingLeft: '0' }}>
          <ProjectSection label="Variant Tags" linkPath="saved-variants" linkText="View All">
            <VariantTags />
          </ProjectSection>
        </Grid.Column>
        <Grid.Column width={4} style={{ paddingLeft: '0' }}>
          <ProjectSection label="Collaborators" editPath="collaborators">
            <ProjectCollaborators />
          </ProjectSection>
          <VerticalSpacer height={30} />
          <ProjectSection label="Gene Lists" editPath="project_gene_list_settings">
            <GeneLists />
          </ProjectSection>
        </Grid.Column>
      </Grid.Row>
    </Grid>

    <SectionHeader>Families</SectionHeader>
    <FamilyTable
      headerStatus={{ title: 'Analysis Statuses', data: props.analysisStatusCounts }}
      exportUrls={[
        { name: 'Families', url: `/api/project/${props.project.projectGuid}/export_project_families` },
        { name: 'Individuals', url: `/api/project/${props.project.projectGuid}/export_project_individuals?include_phenotypes=1` },
      ]}
      showSearchLinks
      fields={props.showDetails ? [
        { id: DESCRIPTION, canEdit: true },
        { id: ANALYSIS_STATUS, canEdit: true },
        { id: ANALYSED_BY, canEdit: true },
        { id: ANALYSIS_NOTES, canEdit: true },
        { id: ANALYSIS_SUMMARY, canEdit: true },
      ] : [{ id: ANALYSIS_STATUS, canEdit: true }]}
    />
  </div>

ProjectPageUI.propTypes = {
  project: PropTypes.object.isRequired,
  analysisStatusCounts: PropTypes.array,
  showDetails: PropTypes.bool,
}

const mapStateToProps = state => ({
  project: getProject(state),
  analysisStatusCounts: getAnalysisStatusCounts(state),
  showDetails: getShowDetails(state),
})

export { ProjectPageUI as ProjectPageUIComponent }

export default connect(mapStateToProps)(ProjectPageUI)

