---
title: <%= hoc_s(:title_country_resources).inspect %>
layout: wide
nav: promote_nav
---

<%= view :signup_button %>

<% if @country == 'la' %>

# Recursos

## ¿Qué hacemos cuando hacemos la Hora del Código?

<div class="handout" style="width: 50%; float: left;">
  
<a href="/la/files/hacemos-la-Hora-del-Codigo.pdf" target="_blank"><img src="/la/images/fit-260/hacemos-la-Hora-del-Codigo.png"></a>
<br />En Español
</div>

<div class="handout" style="width: 50%; float: left;">
  
<a href="/la/files/hacemos-la-Hora-del-Codigo-Ingles.pdf" target="_blank"><img src="/la/images/fit-260/hacemos-la-Hora-del-Codigo-Ingles.png"></a>
<br />En Inglés
</div>

<div style="clear:both"></div>

## Vídeos

  
 <iframe width="560" height="315" src="https://www.youtube.com/embed/HrBh2165KjE" frameborder="0" allowfullscreen mark="crwd-mark"></iframe> 

<a href="https://www.youtube.com/watch?v=HrBh2165KjE"><strong>¿Por qué todos tienen que aprender a programar? Participá de la Hora del Código en Argentina (5 min)</strong></a>

  
  
 <iframe width="560" height="315" src="https://www.youtube.com/embed/_vq6Wpb-WyQ" frameborder="0" allowfullscreen mark="crwd-mark"></iframe> 

  
[**La Hora del Código en Chile (2 min)**](https://www.youtube.com/watch?v=_vq6Wpb-WyQ)

<% elsif @country == 'al' %> <iframe width="560" height="315" src="https://www.youtube.com/embed/AtVzbUZqZcI" frameborder="0" allowfullscreen mark="crwd-mark"></iframe> 

<

p>[**Ora E Kodimit (5 min)**](https://www.youtube.com/embed/AtVzbUZqZcI)

<% elsif @country == 'ca' %>

## Video zapisi <iframe width="560" height="315" src="https://www.youtube.com/embed/k3cg1e27zQM" frameborder="0" allowfullscreen mark="crwd-mark"></iframe> 

<

p>[**Join Nova Scotia for the Hour of Code (3 min)**](https://www.youtube.com/watch?v=k3cg1e27zQM)

<% elsif @country == 'id' %>

Di luar dari fakata bahwa Pekan Edukasi Ilmu Komputer jatuh pada 7 hingga 13 Desember 2015, kami mengetahui bahwa banyak siswa-siswi Indonesia yang menjalankan prosesi ujian. Untuk alasan ini kami memutuskan untuk menjalankan masa kampanye Hour of Code di Indonesia pada 12 hingga 20 Desember 2015. Kita tetap akan merasakan kemeriahan yang sama dan dengan tujuan yang sama namun dengan kebersamaan yang lebih besar karena akan ada lebih banyak siswa-siswi yang dapat mengikutinya.

Mari bersama kita dukung gerakan Hour of Code di Indonesia!

<% elsif @country == 'jp' %>

## Hour of Code(アワーオブコード) 2015紹介ビデオ <iframe width="560" height="315" src="https://www.youtube.com/embed/_C9odNcq3uQ" frameborder="0" allowfullscreen mark="crwd-mark"></iframe> 

<

p>[**Hour of Code(アワーオブコード) 2015紹介ビデオ (1 min)**](https://www.youtube.com/watch?v=_C9odNcq3uQ)

[Hour of Code Lesson Guide](/files/HourofCodeLessonGuideJapan.pdf)

<% elsif @country == 'nl' %>

  
  
  
 <iframe width="560" height="315" src="https://www.youtube.com/embed/0hfb0d5GxSw" frameborder="0" allowfullscreen mark="crwd-mark"></iframe> 

<

p>[**Friends of Technology Hour of Code (2 min)**](https://www.youtube.com/embed/0hfb0d5GxSw)

<% elsif @country == 'pk' %>

اگر آپ کا تعلق پاکستان کےایسے کیمبرج اسکول سے ہے، جہاں دسمبر کے مہینے میں امتحانات لئے جاتے ہیں، تو آپ اپنے اسکول میں آور آف کوڈ کا انقعاد نومبر ٢٣ تا ٢٩ کے دوران بھی کر سکتے ہیں۔ آپ کا شمار دنیا کی سب سے بڑی تعلیمی تقریب میں حصّہ لینے والوں میں ہی کیا جائے گا۔

<% elsif @country == 'ro' %>

Va multumim pentru inregistrare, daca doriti materiale printate pentru promovarea evenimentului, echipa din Romania vi le poate trimite prin curier. Trebuie doar sa trimiteti un email la HOC@adfaber.org si sa le solicitati.

<% elsif @country == 'uk' %>

# How-to Guide for Organizations

## Use this handout to recruit corporations

[<%= localized_image('/images/fit-500x300/corporations.png') %>](%= localized_file('/files/corporations.pdf') %)

## 1) Isprobajte vodiče:

We’ll host a variety of fun, hour-long tutorials, created by a variety of partners. New tutorials are coming to kick off the Hour of Code before <%= campaign_date('full') %>.

**Svi vodiči Sata Kodiranja:**

- Require minimal prep-time for organizers
- Prigodni su za samostalno učenje - dozvoljavajući učenicima da rade vlastitim tempom i na svojoj razini

<a href="https://code.org/learn"><img src="https://code.org/images/tutorials.png"></a>

## 2) Planirajte svoje hardverske potrebe - računala nisu obvezna

The best Hour of Code experience will be with Internet-connected computers. But you don’t need a computer for every participant, and can even do the Hour of Code without a computer at all.

- **Isprobajte vodiče na računalima i uređajima učenika.** Osigurajte se da ispravno funkcioniraju (zvuk i slika).
- **Pregledajte stranicu sa čestitkama (certifikatima)** da biste vidjeli što će učenici vidjeti po završetku.
- **Provide headphones for your group**, or ask students to bring their own, if the tutorial you choose works best with sound.

## 3) Planirajte unaprijed ovisno o vama dostupnoj tehnologiji

- **Nemate dovoljno uređaja?** Koristite [programiranje u parovima](http://www.ncwit.org/resources/pair-programming-box-power-collaborative-learning). When participants partner up, they help each other and rely less on the teacher.
- **Niska propusnost?** Planirajte prikaz video zapisa u prednjem dijelu učionice, tako da svaki učenik ne mora preuzimati vlastitu kopiju video zapisa. Možete isprobati i vodiče koji ne zahtijevaju upotrebu računala i/ili interneta.

## 4) Nadahnite učenike - pokažite im video zapis

Show students an inspirational video to kick off the Hour of Code. Examples:

- Originalni video zapis kada je Code.org pokrenut, u kome su Bill Gates, Mark Zuckerberg i zvijezda NBA-a Chris Bosh (Možete izabrati verzije u trajanju od [1 minute](https://www.youtube.com/watch?v=qYZF6oIZtfc), [5 minuta](https://www.youtube.com/watch?v=nKIu9yen5nc) i [9 minuta](https://www.youtube.com/watch?v=dU1xS07N-FA))
- The [Hour of Code 2013 launch video](https://www.youtube.com/watch?v=FC5FbmsH4fw), or the [Hour of Code 2014 video](https://www.youtube.com/watch?v=96B5-JGA9EQ)
- [Predsjednik Obama poziva sve učenike da nauče informatiku](https://www.youtube.com/watch?v=6XvmhE1J9PY)

**Get your students excited - give them a short intro**

<% elsif @country == 'pe' %>

# La Hora del Código Perú <iframe width="560" height="315" src="https://www.youtube.com/embed/whSt53kn0lM" frameborder="0" allowfullscreen mark="crwd-mark"></iframe> 

<

p>[**Pedro Pablo Kuczynski. Presidente del Perú 2016-2021**](https://www.youtube.com/watch?v=whSt53kn0lM)

<% else %>

# Additional resources coming soon!

<% end %>