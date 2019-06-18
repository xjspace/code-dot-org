function style_num(n) {
  if (n % 2 === 0) {
    return '<b>' + n + '</b>';
  } else {
    return n;
  }
}

require([
  'esri/Map',
  'esri/views/MapView',
  'esri/layers/FeatureLayer',
  'esri/Graphic',
], function(Map, MapView, FeatureLayer) {
  var map = new Map({
    basemap: 'topo-vector',
  });
  var view = new MapView({
    container: 'map',
    map: map,
    center: [-118.80543, 34.027],
    zoom: 5,
  });

  var popupTemplate = {
    content: function() {
      if (parseInt("{description}") % 2 === 0) {
        return '<b>{description}</b>';
      } else {
        return "{description}";
      }
    },
  };

  var trailheadsLayer = new FeatureLayer({
    url:
      'https://services7.arcgis.com/VuvzH0LTXDCAYsLv/arcgis/rest/services/world/FeatureServer/0',
    outFields: ["description"],
    popupTemplate: popupTemplate,
  });

  map.add(trailheadsLayer);
});
