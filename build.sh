#!/bin/sh
# builds the website by importing from the content folder

CURRENT_YEAR=$(date +"%Y")
init () {
	if ! [ -d ./content ]; then mkdir ./content; fi
	printf "# these variables contain the site metadata
# edit them to fit your site\n
TITLE='website title'
FIGLET_TITLE_TEXT='website title'
# available figlet fonts: 
# banner, block, digital, lean, mnemonic, shadow, small, smshadow, standard,
# big, bubble, ivrit, mini, script, slant, smscript, smslant, term
FIGLET_FONT='small'
" > ./content/metadata
}

source_metadata () {
	# source metadata file
	. ./content/metadata
}


add_figlet () {
	printf "<pre>\n" >> $1
	figlet -f small -w 1080 "${FIGLET_TITLE_TEXT}" >> $1
	printf '</pre>\n' >> $1
}


add_navbar () {
printf "\
<div class="navbar">
<ul>
	<li display="inline"><a href="blog.html">blog</a></li>
	<li display="inline"><a href="about.html">about</a></li>
</ul>
</div>\n" >> $1 
}

add_footer () {
printf '
<footer>
	&copy; %s<br>No scripts, no cookies.
</footer>\n' ${CURRENT_YEAR}\
>> $1
}

make_index () {
printf "\
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<link rel="stylesheet" type="text/css" href="style.css">
<title>${TITLE}</title>
</head>
<body>
<header>\n"\
> index.html


add_figlet index.html

printf "\
</header>\n"\
>> index.html

add_navbar index.html

printf '
<div class="row">
<div class="column side">
<!-- left-hand column -->
</div>
<div class="column middle">
</div>
<div class="column side">
<!-- right-hand column -->
</div>
</div> <!-- end row div -->\n'\
>> index.html

add_footer index.html

printf "\
</body>
</html>\
" >> index.html
}

help () {
	echo "Available commands:
	--init
	--run"
}

case $1 in
	--init)
		init
		source_metadata
		exit 1
		;;
	--run)
		source_metadata
		make_index
		exit 1
		;;
	*)
		help
		exit 1;;	
esac
