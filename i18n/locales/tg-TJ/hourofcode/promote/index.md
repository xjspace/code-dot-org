---
title: <%= hoc_s(:title_how_to_promote).inspect %>
layout: wide
nav: promote_nav
---
<%= view :signup_button %>

<% facebook = {:u=>"http://#{request.host}/us"}

twitter = {:url=>"http://hourofcode.com", :related=>'codeorg', :hashtags=>'', :text=>hoc_s(:twitter_donor_text).gsub(/%{random_donor}/, get_random_donor_twitter)} twitter[:hashtags] = 'HourOfCode' unless hoc_s(:twitter_donor_text).include? '#HourOfCode' %>

# Get your community involved in the Hour of Code

## 1. Маълумотро паҳн кунед

Tell your friends about the **#HourOfCode**!

<%= view :share_buttons, facebook:facebook, twitter:twitter %>

## 2. Тамоми мактаби худро ҷалб намоед, то ки Соати рамзро пешниҳод кунад

[Send this email](%= resolve_url('/promote/resources#sample-emails') %) to your principal and challenge every classroom at your school to sign up.

## 3. Соҳибкорро ба чорабинии худ ҷалб намоед

[Send this email](%= resolve_url('/promote/resources#sample-emails') %) to your manager or company's CEO.

## 4. Ба Соати рамз дар маҳаллаи худ мусоидат кунед

[Recruit a local group](%= resolve_url('/promote/resources#sample-emails') %)— boy/girl scouts club, church, university, veterans group, labor union, or even some friends. You don't have to be in school to learn new skills. Use these [posters, banners, stickers, videos and more](%= resolve_url('/promote/resources') %) for your own event.

## 5. Намояндаро аз ҳайати ҳуқумати маҳаллӣ барои дастгирӣ намудани Соати рамз даъват намоед

[Send this email](%= resolve_url('/promote/resources#sample-emails') %) to your local representatives, city council, or school board and invite them to visit your school for the Hour of Code. It can help build support for computer science in your area beyond one hour.

<%= view :signup_button %>