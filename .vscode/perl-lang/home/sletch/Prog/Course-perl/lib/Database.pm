{"version":5,"vars":[{"containerName":"DBI::File","kind":2,"name":"Path","line":4},{"name":"new","definition":"sub","line":7,"containerName":"main::","signature":{"documentation":"","parameters":[{"label":"$class"},{"label":"$config"}],"label":"new($class,$config)"},"kind":12,"detail":"($class,$config)","range":{"end":{"character":9999,"line":13},"start":{"character":0,"line":7}},"children":[{"containerName":"new","localvar":"my","name":"$class","definition":"my","line":8,"kind":13},{"kind":13,"name":"$config","line":8,"containerName":"new"},{"containerName":"new","kind":13,"name":"$self","localvar":"my","definition":"my","line":9},{"name":"$config","line":10,"kind":13,"containerName":"new"},{"name":"get","line":10,"kind":12,"containerName":"new"},{"containerName":"new","kind":13,"name":"$self","line":12},{"line":12,"name":"$class","kind":13,"containerName":"new"}]},{"containerName":"File","line":8,"name":"Spec","kind":2},{"name":"db_path","line":10,"kind":12},{"containerName":"main::","signature":{"label":"init($self)","parameters":[{"label":"$self"}],"documentation":""},"line":15,"definition":"sub","name":"init","children":[{"kind":13,"name":"$self","localvar":"my","definition":"my","line":16,"containerName":"init"},{"line":19,"name":"$db_dir","localvar":"my","definition":"my","kind":13,"containerName":"init"},{"kind":12,"line":19,"name":"catpath","containerName":"init"},{"kind":12,"name":"splitpath","line":19,"containerName":"init"},{"containerName":"init","name":"$self","line":19,"kind":13},{"name":"$db_dir","line":20,"kind":13,"containerName":"init"},{"containerName":"init","name":"$db_dir","line":20,"kind":13},{"containerName":"init","line":22,"definition":"my","localvar":"my","name":"$dbh","kind":13},{"containerName":"init","name":"$self","line":22,"kind":13},{"name":"connect","line":22,"kind":12,"containerName":"init"},{"containerName":"init","kind":13,"line":24,"name":"$dbh"},{"kind":12,"line":24,"name":"do","containerName":"init"},{"name":"$dbh","line":35,"kind":13,"containerName":"init"},{"containerName":"init","line":35,"name":"do","kind":12},{"containerName":"init","kind":13,"name":"$dbh","line":47},{"containerName":"init","kind":12,"line":47,"name":"do"},{"containerName":"init","line":58,"name":"$dbh","kind":13},{"name":"do","line":58,"kind":12,"containerName":"init"},{"containerName":"init","line":71,"name":"$dbh","kind":13},{"containerName":"init","kind":12,"name":"disconnect","line":71}],"range":{"start":{"line":15,"character":0},"end":{"character":9999,"line":72}},"detail":"($self)","kind":12},{"containerName":"Spec","line":19,"name":"File","kind":12},{"containerName":"Spec","kind":12,"line":19,"name":"File"},{"line":19,"name":"db_path","kind":12},{"line":20,"name":"make_path","kind":12},{"signature":{"documentation":"","label":"connect($self)","parameters":[{"label":"$self"}]},"containerName":"main::","name":"connect","definition":"sub","line":74,"range":{"end":{"character":9999,"line":86},"start":{"line":74,"character":0}},"children":[{"containerName":"connect","name":"$self","localvar":"my","definition":"my","line":75,"kind":13},{"containerName":"connect","line":76,"name":"connect","kind":12}],"kind":12,"detail":"($self)"},{"kind":12,"name":"DBI","line":76},{"name":"RaiseError","line":81,"kind":12},{"kind":12,"name":"AutoCommit","line":82},{"kind":12,"name":"sqlite_unicode","line":83}]}