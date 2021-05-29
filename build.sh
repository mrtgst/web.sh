#!/bin/sh
# builds the website by importing from the content folder

init () {
	if ! [ -d ./content ]; then mkdir ./content; fi
	printf "# these variables contain the site metadata
# edit them to fit your site\n
TITLE='website title'
FIGLET_TITLE_TEXT='website title'
" > ./content/metadata
}

source_metadata () {
	# source metadata file
	. ./content/metadata
}


add_figlet () {
	echo "<pre>" >> $1
	figlet -f smkeyboard -w 1080 "${FIGLET_TITLE_TEXT}" >> $1
	echo '</pre>' >> $1
}



make_index () {
echo "\
<html>
<head>
<title>${TITLE}</title>
</head>
<body>" > index.html
add_figlet 'index.html'
echo "\
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
