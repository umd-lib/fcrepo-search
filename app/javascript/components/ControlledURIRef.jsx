import React from "react"
import PropTypes from "prop-types"

/**
 * Input component with a dropdown whose values come from a controlled vocabulary.
 *
 *  Sample Rails view usage:
 *
 * ```
 * <%=
 *   react_component(
 *     :ControlledURIRef, {
 *       paramPrefix: 'example',
 *       name: 'object_type',
 *       value: 'http://example.com/foo#bar',
 *       vocab: Vocabulary.find_by(identifier: 'foo').as_hash
 *     }
 *   )
 * %>
 * ```
 *
 * When used in a form, this will submit the array `example[object_type][]`
 * with a single value `'http://example.com/foo#bar'`
 */
class ControlledURIRef extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      value: props.value
    }

    this.handleChange = this.handleChange.bind(this);
  };

  handleChange(event) {
    this.setState({value: event.target.value})
  };

  render () {
    let inputName = `${this.props.paramPrefix}[${this.props.name}][]`
    return (
      <React.Fragment>
        <select name={inputName} value={this.state.value} onChange={this.handleChange}>
          <option key="" value=""/>
          {Object.entries(this.props.vocab).map(([uri, label]) => (
              <option key={uri} value={uri}>{label}</option>
          ))}
        </select>
      </React.Fragment>
    );
  }
}

ControlledURIRef.propTypes = {
  /**
   * The name of the element, used to with `paramPrefix` to construct the
   * parameter sent via the form submission.
   */
  name: PropTypes.string,
  /**
   * Combined with the name (`<paramPrefix>[<name>][]`) to construct the
   * parameter sent via the form submission.
   */
  paramPrefix: PropTypes.string,
  /**
   * The default selected value for the dropdown
   */
  value: PropTypes.string,
  /**
   * The vocabulary to display
   */
  vocab: PropTypes.object,
}

ControlledURIRef.defaultProps = {
  vocab: {},
}

export default ControlledURIRef
