function addSharedControlers() {

  /* Controles de mesure */
  var control;
  for(var key in measureControls) {
    control = measureControls[key];
    control.events.on({
      "measure": handleMeasurements,
      "measurepartial": handleMeasurements
    });
    map.addControl(control);
  }

  $('#ruler_measure, #square_measure').click(function(e){
    e.preventDefault();
     for(key in measureControls) {
        var control = measureControls[key];
        if($(this).attr('measure_type') == key ){
          control.activate();
        }else{
          control.deactivate();
        }
      }
  });

  $('#hand_control').click(function(e){
    e.preventDefault();
     for(key in measureControls) {
        var control = measureControls[key];
        control.deactivate();
      }
  });

  /* Retour a la position initiale */

  $('#position_btn').click(function(e){
    e.preventDefault();
    map.zoomToMaxExtent();  
  });
  
  /* Affichage des coordonees */

  map.events.register("mousemove", map, function(e) {
            var pixel = this.events.getMousePosition(e);
            var position = map.getLonLatFromPixel(pixel);
            $("#coords").text("x: "+parseInt(position.lon) + " / y: " + parseInt(position.lat));
  });
  
  /* Affichage de la projection */

  $("#projection").text(map.getProjection());

  /* GetFeaturesInfo */

  // Highlight de la carte
  select = new OpenLayers.Layer.Vector("Selection", {styleMap: 
                  new OpenLayers.Style(OpenLayers.Feature.Vector.style["select"])
          });
  map.addLayer(select);
  getFeatures = new OpenLayers.Control.GetFeature({
                protocol: OpenLayers.Protocol.WFS.fromWMSLayer(layer),
                box: false,
                hover: false,
                multipleKey: "shiftKey",
                toggleKey: "ctrlKey"
            });  
  
  getFeatures.events.register("featureselected", this, function(e) {
      select.addFeatures([e.feature]);
  });
  getFeatures.events.register("featureunselected", this, function(e) {
      select.removeFeatures([e.feature]);
  });
  
  // Affichage de la popup
  var popup = null;
  var featureInfos = new OpenLayers.Control.WMSGetFeatureInfo({
    url: layer.url, 
    queryVisible: true,
    eventListeners: {
      getfeatureinfo: function(event) {
           if (popup != null) {
              popup.destroy();
           }
           popup = new OpenLayers.Popup.FramedCloud(
                        "featuresPopup", 
                        map.getLonLatFromPixel(event.xy),
                        null,
                        event.text,
                        null,
                        true
                    );
          map.addPopup(popup);
        }
      }
    });

  // Activation des commandes au click bouton
  map.addControls([featureInfos, getFeatures]);
  getFeatures.activate();
  $("#btn-features").click(function(e){
    if(featureInfos.active) {
      featureInfos.deactivate();
      getFeatures.deactivate();
      $(".olMap").css("cursor", "");
    } else {
      featureInfos.activate();
      getFeatures.activate();
      $(".olMap").css("cursor", "crosshair");
    }
  });

};