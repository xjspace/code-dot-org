$(document).ready(function() {
  mapboxgl.accessToken =
    'pk.eyJ1IjoiYmV0aGFueWNvZGVvcmciLCJhIjoiY2p3djN3czBoMDFkdjQ4b214dnpxeHpnNyJ9.X8_R6q8yWmNLfRy8jB_X5w';
  var map = new mapboxgl.Map({
    container: 'map',
    style: 'mapbox://styles/mapbox/streets-v11',
    zoom: 1,
    center: [-98, 39],
  });
  map.on('load', function() {
    map.addSource('volunteers', {
      type: 'geojson',
      data: '/world.json',
      cluster: true,
      clusterMaxZoom: 15,
      clusterRadius: 50
    });
    map.getSource('volunteers').setData('/world.json');

    map.addLayer({
      id: 'clusters',
      type: 'circle',
      source: 'volunteers',
      filter: ['has', 'point_count'],
      paint: {
        'circle-color': [
          'step',
          ['get', 'point_count'],
          '#51bbd6',
          100,
          '#f1f075',
          750,
          '#f28cb1',
        ],
        'circle-radius': ['step', ['get', 'point_count'], 20, 100, 30, 750, 40],
      },
    });

    map.addLayer({
      id: 'cluster-count',
      type: 'symbol',
      source: 'volunteers',
      filter: ['has', 'point_count'],
      layout: {
        'text-field': '{point_count_abbreviated}',
        'text-font': ['DIN Offc Pro Medium', 'Arial Unicode MS Bold'],
        'text-size': 12,
      },
    });

    map.addLayer({
      id: 'unclustered-point',
      type: 'circle',
      source: 'volunteers',
      filter: ['!', ['has', 'point_count']],
      paint: {
        'circle-color': '#11b4da',
        'circle-radius': 4,
        'circle-stroke-width': 1,
        'circle-stroke-color': '#fff',
      },
    });

    map.on('click', 'clusters', function (e) {
      var features = map.queryRenderedFeatures(e.point, { layers: ['clusters'] });
      var clusterId = features[0].properties.cluster_id;
      map.getSource('volunteers').getClusterExpansionZoom(clusterId, function (err, zoom) {
        if (err)
          return;
         
        map.easeTo({
          center: features[0].geometry.coordinates,
          zoom: zoom
        });
      });
    });

    map.on('click', 'unclustered-point', function (e) {
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
    /*
  map.addLayer({
    id: 'volunteers',
    type: 'circle',
    source: 'volunteers',
    layout: {
      visibility: 'visible',
    },
    paint: {
      'circle-radius': 8,
      'circle-color': 'rgba(55,148,179,1)',
    },
  });*/
  });
});
