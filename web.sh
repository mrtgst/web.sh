#!/bin/sh
TARGET_DIR=$2
CURRENT_YEAR=$(date +"%Y")
CURRENT_DATE=$(date +"%Y-%m-%d")
init () {
	if ! [ -d ${TARGET_DIR}/content ]; then mkdir -p ${TARGET_DIR}/content; fi
	if ! [ -d ${TARGET_DIR}/blog ]; then mkdir -p ${TARGET_DIR}/blog; fi
    printf "# Blog title\nSome blog text." > ${TARGET_DIR}/blog/${CURRENT_DATE}_blog-title.md
	echo "" > ${TARGET_DIR}/content/blank_text
	echo "Welcome to ${0}" > ${TARGET_DIR}/content/index_text
	echo "Something about ${0}" > ${TARGET_DIR}/content/about_text
	printf "# these variables contain the site metadata
# edit them to fit your site\n
TITLE=%s
FIGLET_TITLE_TEXT=%s
# available figlet fonts: 
# banner, block, digital, lean, mnemonic, shadow, small, smshadow, standard,
# big, bubble, ivrit, mini, script, slant, smscript, smslant, term
FIGLET_FONT='small'
" ${0} ${0} > ${TARGET_DIR}/content/metadata
cp ./style.css ${TARGET_DIR}
echo "Created ${TARGET_DIR}/content folder with template files."
}

source_metadata () {
	# source metadata file
	. ${TARGET_DIR}/content/metadata
}


add_figlet () {
	printf "<pre>\n" >> "$1"
	figlet -f small -w 1080 "${FIGLET_TITLE_TEXT}" >> "$1"
	printf '</pre>\n' >> $1
}


add_navbar () {
printf "\
<div class="navbar">
<ul>
	<li display="inline"><a href="blog.html">blog</a></li>
	<li display="inline"><a href="about.html">about</a></li>
</ul>
</div>\n" >> ${1} 
}

add_footer () {
printf '
<footer>
	&copy; %s<br>
    Built with <a href='https://github.com/mrtgst/web.sh'>web.sh</a><br>
    No scripts, no cookies
</footer>\n' ${CURRENT_YEAR}\
>> $1
}

add_header () {
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
> $1

echo '<div class=banner>' >> $1
echo '<a href=index.html>' >> $1
add_figlet $1 
echo '</a>' >> $1
echo '</div>' >> "$1"

printf '
</header>\n'\
>> $1 

add_navbar $1
}


build_page () {
TARGET_FILE=${1}
SOURCE_FILE=${2}
BUILD_TARGET=${TARGET_DIR}/${TARGET_FILE}
BUILD_SOURCE=${TARGET_DIR}/content/${SOURCE_FILE}

add_header ${BUILD_TARGET}

printf '
<div class="row">
<div class="column side">
</div>
<div class="column middle">\n'\
>> "${BUILD_TARGET}" 

if [ -e ${BUILD_SOURCE} ]; then
	cat "${BUILD_SOURCE}" >> "${BUILD_TARGET}"
fi

printf '
</div>
<div class="column side">
</div>
</div>\n'\
>> "${BUILD_TARGET}"

add_footer "${BUILD_TARGET}"

printf "\
</body>
</html>\
" >> "${BUILD_TARGET}"

}

build_blog_posts () {
POSTS=$(ls ${TARGET_DIR}/blog/*.md)
for i in ${POSTS}; do
    j=${i%.*} # remove .md
    pandoc $i --from markdown --to html --output $j.tmp
    build_blog_page $j.html $j.tmp 
    rm -f $j.tmp
done
cp $j.html ${TARGET_DIR}/blog.html
}

build_blog_page () {
BUILD_TARGET=${1}
BUILD_SOURCE=${2}

add_header ${BUILD_TARGET}

printf '
<div class="row">
<div class="column side">
Posts
<ul>
	<li display="inline"><a href="1.html">2021-05-30</a></li>
	<li display="inline"><a href="2.html">2021-05-29</a></li>
</ul>
</div>
<div class="column middle">\n'\
>> "${BUILD_TARGET}" 


if [ -e ${BUILD_SOURCE} ]; then
	cat "${BUILD_SOURCE}" >> "${BUILD_TARGET}"
fi

printf '
</div>
<div class="column side">
</div>
</div>\n'\
>> "${BUILD_TARGET}"

add_footer "${BUILD_TARGET}"

printf "\
</body>
</html>\
" >> "${BUILD_TARGET}"
}

help () {
	echo "web.sh $VERSION. Available commands:
	--init destination 
	--build destination"
}

case $1 in
	--init)
		init
		source_metadata
		exit 1
		;;
	--build)
		source_metadata
		build_page index.html index_text
		build_page about.html about_text 
        build_blog_posts
		exit 1
		;;
	*)
		help
		exit 1
		;;
esac