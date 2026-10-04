{{flutter_js}}
{{flutter_build_config}}

// Deep links must load the same application and renderer as the public root.
// Release builds include CanvasKit locally (--no-web-resources-cdn), so page
// rendering does not depend on Google CDN requests succeeding in a crawler.
_flutter.loader.load({
  config: {
    entrypointBaseUrl: '/',
    assetBase: '/',
    canvasKitBaseUrl: '/canvaskit/',
  },
});
