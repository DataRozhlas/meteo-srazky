ig.drawPrecips!
switch window.location.hash
| '#medard'
  d3.select ig.containers.base .append \div
    ..attr \class "year-part medard"
    ..html "Medard: 8. června"
