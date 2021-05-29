#!/bin/sh
# builds the website by importing from the content folder

init () {
	if ! [ -d ./content ]; then mkdir ./content; fi
	printf "# these variables contain the site metadata
# edit them to fit your site\n
TITLE='website title'
" > ./content/metadata
}

source_metadata () {
	# source metadata file
	. ./content/metadata
}

run () {
echo "\
<html>
<head>
<title>${TITLE}</title>
</head>
<body>
<pre>
 _________ ____ ____ ____ ____ ____ ____ ____ ____ ____ ____ _________
||       |||m |||a |||. |||r |||t |||i |||n |||. |||s |||h |||       ||
||_______|||__|||__|||__|||__|||__|||__|||__|||__|||__|||__|||_______||
|/_______\|/__\|/__\|/__\|/__\|/__\|/__\|/__\|/__\|/__\|/__\|/_______\|
</pre>
</body>
</html>\
" > index.html
}

case $1 in
	--init)
		init
		source_metadata
		;;
	--run)
		source_metadata
		run
		;;
	*)
esac
