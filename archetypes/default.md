+++
date = '{{ .Date }}'
draft = true
title = '{{ replace .File.ContentBaseName "-" " " | title }}'
[sitemap]
changefreq = "monthly"
priority = 0.8
+++
