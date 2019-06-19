import PropTypes from 'prop-types';
import React from 'react';
// import {connect} from 'react-redux';
import {geoMercator, geoPath} from 'd3-geo';
import {scaleSqrt} from 'd3-scale';
import {feature} from 'topojson-client';

const RADIUS = 70;
const WIDTH = 400;
const HEIGHT = 400;

class MercatorMap extends React.Component {
  static propTypes = {
    data: PropTypes.any
  };

  state = {
    mercator: '',
    data: this.props.data
  };

  async componentDidMount() {
    let value = await this.mercator();
    this.setState({
      mercator: value
    });
  }

  projection() {
    return geoMercator()
      .scale(RADIUS)
      .translate([WIDTH / 2, HEIGHT / 2]);
  }

  async mercator() {
    let displayWorldMap = async function() {
      const worldMapUrl = 'https://unpkg.com/world-atlas@1/world/110m.json';
      let response = await fetch(worldMapUrl);

      let worldData = await response.json();

      return feature(worldData, worldData.objects.countries).features;
    };

    let worldMap = await displayWorldMap();

    let dataPointRadius = function() {
      const scale = scaleSqrt()
        .domain([0, 100])
        .range([0, 6]);
      return scale(Math.exp(3));
    };

    // TODO: consult with product/design about color scheme
    return (
      <svg width={WIDTH} height={HEIGHT}>
        <g className="countries">
          {worldMap.map((d, i) => (
            <path
              key={`path-${i}`}
              d={geoPath().projection(this.projection())(d)}
              className="country"
              fill={'green'}
              stroke="#FFFFFF"
              strokeWidth={0.5}
            />
          ))}
        </g>
        <g className="markers">
          <circle
            cx={
              this.projection()([this.props.data.lat, this.props.data.long])[0]
            }
            cy={
              this.projection()([this.props.data.lat, this.props.data.long])[1]
            }
            r={dataPointRadius()}
            fill="#E91E63"
            className="marker"
          />
        </g>
      </svg>
    );
  }

  render() {
    return <div>{this.state.mercator}</div>;
  }
}

export default MercatorMap;
