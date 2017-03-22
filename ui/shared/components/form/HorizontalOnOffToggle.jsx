import React from 'react'
import { Icon } from 'semantic-ui-react'

//const refBlurHandler = (ref) => { if (ref) ref.blur() }

const HorizontalOnOffToggle = props =>
  <a
    tabIndex="0"
    onClick={props.onClick}
    className="clickable"
    style={{ verticalAlign: 'bottom' }}
  >
    {props.isOn ?
      <Icon size="large" style={{ color: props.color || '#BBBBBB' }} name="toggle on" /> :
      <Icon size="large" style={{ color: '#BBBBBB' }} name="toggle off" />
    }
  </a>

HorizontalOnOffToggle.propTypes = {
  onClick: React.PropTypes.func.isRequired,
  isOn: React.PropTypes.bool,
  color: React.PropTypes.string,
}

export default HorizontalOnOffToggle