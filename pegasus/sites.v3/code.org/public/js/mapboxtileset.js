$(document).ready(function() {
  mapboxgl.accessToken =
    'pk.eyJ1IjoiYmV0aGFueWNvZGVvcmciLCJhIjoiY2p3djN3czBoMDFkdjQ4b214dnpxeHpnNyJ9.X8_R6q8yWmNLfRy8jB_X5w';
  var map = new mapboxgl.Map({
    container: 'map',
    style: 'mapbox://styles/mapbox/streets-v11',
    zoom: 4,
    center: [-98, 39],
  });
  map.on('load', function() {
    map.addLayer({
      id: 'volunteers0',
      type: 'circle',
      source: {
        type: 'vector',
        url: 'mapbox://bethanycodeorg.8vx8uq7m',
      },
      layout: {
        visibility: 'visible',
      },
      paint: {
        'circle-radius': 4,
        'circle-color': 'rgba(55,148,179,1)',
      },
      'source-layer': 'hoc-0-a0a4k1',
    });
    map.addLayer({
      id: 'volunteers1',
      type: 'circle',
      source: {
        type: 'vector',
        url: 'mapbox://bethanycodeorg.apt2fxl5',
      },
      layout: {
        visibility: 'visible',
      },
      paint: {
        'circle-radius': 4,
        'circle-color': 'rgba(55,148,179,1)',
      },
      'source-layer': 'hoc-1-27dxoo',
    });
    map.addLayer({
      id: 'volunteers2',
      type: 'circle',
      source: {
        type: 'vector',
        url: 'mapbox://bethanycodeorg.c2y1uy6j',
      },
      layout: {
        visibility: 'visible',
      },
      paint: {
        'circle-radius': 4,
        'circle-color': 'rgba(55,148,179,1)',
      },
      'source-layer': 'hoc-2-6z530w',
    });
    map.addLayer({
      id: 'volunteers3',
      type: 'circle',
      source: {
        type: 'vector',
        url: 'mapbox://bethanycodeorg.cewp8vc3',
      },
      layout: {
        visibility: 'visible',
      },
      paint: {
        'circle-radius': 4,
        'circle-color': 'rgba(55,148,179,1)',
      },
      'source-layer': 'hoc-3-d03g6l',
    });

    map.on('click', 'volunteers0', function(e) {
      var coordinates = e.features[0].geometry.coordinates.slice();
      var description = e.features[0].properties.description;

      // Ensure that if the map is zoomed out such that multiple
      // // copies of the feature are visible, the popup appears
      // // over the copy being pointed to.
      while (Math.abs(e.lngLat.lng - coordinates[0]) > 180) {
        coordinates[0] += e.lngLat.lng > coordinates[0] ? 360 : -360;
      }
      new mapboxgl.Popup()
        .setLngLat(coordinates)
        .setHTML(description)
        .addTo(map);
    });
  });
});
