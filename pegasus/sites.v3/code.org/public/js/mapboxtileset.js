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
      id: 'volunteers',
      type: 'circle',
      source: {
        type: 'vector',
        url: 'mapbox://bethanycodeorg.world-test',
      },
      layout: {
        visibility: 'visible',
      },
      paint: {
        'circle-radius': 4,
        'circle-color': 'rgba(55,148,179,1)',
      },
      'source-layer': 'original',
    });

    map.on('click', 'volunteers', function(e) {
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
