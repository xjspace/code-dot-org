import PropTypes from 'prop-types';
import React, {Component} from 'react';
import i18n from '@cdo/locale';
import {STATES} from '../geographyConstants';
import {styles} from './census2017/censusFormStyles';
import GoogleSchoolLocationSearchField from './GoogleSchoolLocationSearchField';

const schoolTypes = [
  '',
  i18n.schoolTypeCharter(),
  i18n.schoolTypePrivate(),
  i18n.schoolTypePublic(),
  i18n.other()
];

const singleLineLayoutStyles = {
  display: 'table-cell',
  width: 210,
  verticalAlign: 'top',
  minHeight: 42,
  fontSize: 13,
  fontFamily: '"Gotham 4r", sans-serif',
  color: '#333',
  padding: 0
};

const singleLineLabelStyles = {
  display: 'table',
  width: '100%',
  height: 42,
  marginBottom: 0
};

const singleLineFieldStyles = {
  width: '100%',
  height: 'auto'
};

const singleLineInputStyles = {
  height: 'auto',
  width: '100%',
  marginBottom: 0,
  boxSizing: 'border-box'
};

const singleLineDropdownStyles = {
  marginTop: 0,
  marginBottom: 0,
  width: '100%'
};

const OMIT_FIELD = '__omit_field__';

export default class SchoolNotFound extends Component {
  static propTypes = {
    onChange: PropTypes.func,
    schoolName: PropTypes.string,
    schoolCity: PropTypes.string,
    schoolState: PropTypes.string,
    schoolZip: PropTypes.string,
    schoolType: PropTypes.string,
    schoolLocation: PropTypes.string,
    country: PropTypes.string,
    controlSchoolLocation: PropTypes.bool,
    fieldNames: PropTypes.object,
    showErrorMsg: PropTypes.bool,
    isNcesSchool: PropTypes.bool,
    singleLineLayout: PropTypes.bool,
    showRequiredIndicators: PropTypes.bool,
    schoolNameLabel: PropTypes.string,
    // Note: Google location search requires the following line to be present in the haml where this component is used:
    // %script{type: "text/javascript", src: "https://maps.googleapis.com/maps/api/js?client=#{CDO.google_maps_client_id}&sensor=true&libraries=places,geometry&v=3.7"}
    useGoogleLocationSearch: PropTypes.bool
  };

  static defaultProps = {
    showRequiredIndicators: true,
    controlSchoolLocation: false,
    schoolNameLabel: i18n.schoolName(),
    fieldNames: {
      schoolName: 'school_name_s',
      schoolType: 'school_type_s',
      schoolCity: 'school_city_s',
      schoolState: 'school_state_s',
      schoolZip: 'school_zip_s',
      googleLocation: 'registration_location'
    }
  };

  static OMIT_FIELD = OMIT_FIELD;

  handleChange = (field, event) => {
    this.props.onChange(field, event);
  };

  isNotBlank(value) {
    return value && value !== '';
  }

  isFieldValid(fieldValue) {
    if (OMIT_FIELD === fieldValue || this.isNotBlank(fieldValue)) {
      return true;
    } else {
      return false;
    }
  }

  isValid() {
    if (
      !this.isFieldValid(this.props.schoolName) ||
      !this.isFieldValid(this.props.schoolType)
    ) {
      return false;
    }

    if (this.props.useGoogleLocationSearch && this.locationSearchRef) {
      return this.isFieldValid(this.locationSearchRef.value());
    } else {
      return (
        this.isFieldValid(this.props.schoolCity) &&
        this.isFieldValid(this.props.schoolState) &&
        this.isFieldValid(this.props.schoolZip)
      );
    }
  }

  // isLabelRequired is a check to display an asterisk next to the
  // required field name.
  renderLabel(text, isLabelRequired = true) {
    const {singleLineLayout, showRequiredIndicators} = this.props;
    const questionStyle = {
      ...styles.question,
      ...(singleLineLayout && singleLineLayoutStyles)
    };
    return (
      <div style={questionStyle}>
        {text}
        {showRequiredIndicators && isLabelRequired && (
          <span style={styles.asterisk}> *</span>
        )}
      </div>
    );
  }

  render() {
    const {singleLineLayout} = this.props;
    const labelStyle = {...(singleLineLayout && singleLineLabelStyles)};
    const fieldStyle = {
      ...styles.field,
      ...(singleLineLayout && singleLineFieldStyles)
    };
    const inputStyle = {
      ...styles.input,
      ...(singleLineLayout && singleLineInputStyles)
    };
    const dropdownStyle = {
      ...styles.schoolNotFoundDropdown,
      ...(singleLineLayout && singleLineDropdownStyles)
    };
    const showError = this.props.showErrorMsg && !this.isValid();
    const errorDiv = (
      <div style={styles.errors}>{i18n.schoolInfoRequired()}</div>
    );

    // Check if country selected is US or non-US.  This new check
    // is used to decide which fields in the school info interstitial
    // form should be required.
    let countryIsUS = false;
    if (this.props.country && this.props.country === 'United States') {
      countryIsUS = true;
    }

    // An asterisk is not displayed next to the field name if
    // school type is non-nces school
    let isLabelRequired = countryIsUS;
    if (!this.props.isNcesSchool) {
      isLabelRequired = false;
    }

    return (
      <div>
        {!singleLineLayout && (
          <div style={styles.question}>
            {i18n.schoolNotFoundDescription()}
            {showError && errorDiv}
          </div>
        )}
        <div>
          {this.props.schoolName !== OMIT_FIELD && (
            <div style={fieldStyle}>
              <label style={labelStyle}>
                {this.renderLabel(this.props.schoolNameLabel, isLabelRequired)}
                <input
                  id="school_name"
                  type="text"
                  name={this.props.fieldNames.schoolName}
                  value={this.props.schoolName}
                  onChange={this.handleChange.bind(this, 'schoolName')}
                  style={inputStyle}
                />
              </label>
            </div>
          )}
          {this.props.schoolType !== OMIT_FIELD && (
            <div style={fieldStyle}>
              <label style={labelStyle}>
                {this.renderLabel(i18n.schoolType(), countryIsUS)}
                <select
                  id="school_type"
                  name={this.props.fieldNames.schoolType}
                  value={this.props.schoolType}
                  onChange={this.handleChange.bind(this, 'schoolType')}
                  style={dropdownStyle}
                >
                  {schoolTypes.map((schoolType, index) => (
                    <option value={schoolType} key={index}>
                      {schoolType}
                    </option>
                  ))}
                </select>
              </label>
            </div>
          )}
        </div>
        <div>
          {this.props.schoolCity !== OMIT_FIELD &&
            !this.props.useGoogleLocationSearch && (
              <div style={fieldStyle}>
                <label style={labelStyle}>
                  {this.renderLabel(i18n.schoolCity())}
                  <input
                    id="school_city"
                    type="text"
                    name={this.props.fieldNames.schoolCity}
                    value={this.props.schoolCity}
                    onChange={this.handleChange.bind(this, 'schoolCity')}
                    style={inputStyle}
                  />
                </label>
              </div>
            )}
          {this.props.schoolState !== OMIT_FIELD &&
            !this.props.useGoogleLocationSearch && (
              <div style={fieldStyle}>
                <label style={labelStyle}>
                  {this.renderLabel(i18n.schoolState())}
                  <select
                    id="school_state"
                    name={this.props.fieldNames.schoolState}
                    value={this.props.schoolState}
                    onChange={this.handleChange.bind(this, 'schoolState')}
                    style={dropdownStyle}
                  >
                    {STATES.map((state, index) => (
                      <option value={state} key={index}>
                        {state}
                      </option>
                    ))}
                  </select>
                </label>
              </div>
            )}
        </div>
        {this.props.schoolZip !== OMIT_FIELD &&
          !this.props.useGoogleLocationSearch && (
            <div style={fieldStyle}>
              <label style={labelStyle}>
                {this.renderLabel(i18n.schoolZip())}
                <input
                  id="school_zipcode"
                  type="text"
                  name={this.props.fieldNames.schoolZip}
                  value={this.props.schoolZip}
                  onChange={this.handleChange.bind(this, 'schoolZip')}
                  style={inputStyle}
                />
              </label>
            </div>
          )}
        {this.props.useGoogleLocationSearch && (
          <div style={fieldStyle}>
            <label style={labelStyle}>
              {this.renderLabel(i18n.schoolCityTown(), false)}
              <GoogleSchoolLocationSearchField
                ref={el => (this.locationSearchRef = el)}
                name={this.props.fieldNames.googleLocation}
                isControlledInput={this.props.controlSchoolLocation}
                value={this.props.schoolLocation}
                onChange={this.handleChange.bind(this, 'schoolLocation')}
                style={inputStyle}
              />
            </label>
          </div>
        )}
        <div style={styles.clear} />
        {singleLineLayout && showError && errorDiv}
      </div>
    );
  }
}
