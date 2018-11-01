set num=8
set name=real-time-chart

call ng g c d3/d3-samples/sample-%num% --dry-run

call ng g c d3/d3-samples/sample-%num%/%name% --dry-run

rem call ng g c d3/d3-samples/sample-3
rem call ng g c d3/d3-samples/sample-3/brush-and-zoom-area-chart
