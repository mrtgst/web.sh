#!/bin/bash
VERSION=0.1.28
TARGET_DIR=$2
CURRENT_YEAR=$(date +"%Y")
CURRENT_DATE=$(date +"%Y-%m-%d")

get_size () {
	# gets size in kB
	SIZE=$(du -b $1 | tail -n1 | cut -d $'\t' -f1)
	SIZE=$(( SIZE / 1000 ))
}

init () {
	# initiate template files
	if ! [ -d ${TARGET_DIR}/content ]; then mkdir -p ${TARGET_DIR}/content; fi
	if ! [ -d ${TARGET_DIR}/blog ]; then 
		mkdir -p ${TARGET_DIR}/blog  
    	printf "Some blog text." > ${TARGET_DIR}/blog/${CURRENT_DATE}_Blog-Title.md
	fi
	if ! [ -e ${TARGET_DIR}/content/blank_text ]; then echo "" > ${TARGET_DIR}/content/blank_text; fi
	if ! [ -e ${TARGET_DIR}/content/home_text ]; then echo "Welcome to ${0}" > ${TARGET_DIR}/content/home_text; fi
	if ! [ -e ${TARGET_DIR}/content/about_text ]; then echo "Something about ${0}" > ${TARGET_DIR}/content/about_text; fi

	# write to metadata file
	if ! [ -e ${TARGET_DIR}/content/metadata ]; then
		printf "# these variables contain the site metadata
		# edit them to fit your site\n
		TITLE=%s
		FIGLET_TITLE_TEXT=%s
		# available figlet fonts: 
		# banner, block, digital, lean, mnemonic, shadow, small, smshadow, standard,
		# big, bubble, ivrit, mini, script, slant, smscript, smslant, term
		FIGLET_FONT='small'
		" ${0} ${0} > ${TARGET_DIR}/content/metadata
		echo "Wrote ${TARGET_DIR}/content/metadata file"
	fi

	# copy stylesheet
	cp ./style.css ${TARGET_DIR} &&\
	echo "Copied stylesheet to ${TARGET_DIR}/style.css"
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
	local build_target=$1
	local link_prefix=$2
	printf "\
	<div class="navbar">
	<ul>
		<li display="inline"><a href="%sindex.html">home</a></li>
		<li display="inline"><a href="%sblog.html">blog</a></li>
		<li display="inline"><a href="%sabout.html">about</a></li>
	</ul>
	</div>\n" $link_prefix $link_prefix $link_prefix >> $build_target 
}

add_footer () {
	local build_target=$1
	printf '
	<footer>
	<div class=row>
	<div class=footer>
		&copy; %s<br>
		Built with <a href='https://github.com/mrtgst/web.sh'>web.sh %s</a><br>
		No scripts, no cookies
	</div>
	</div>
	</footer>\n' ${CURRENT_YEAR} ${VERSION}\
	>> $build_target
}

add_header () {
	local build_target=$1
	local link_prefix=$2

	printf "\
	<!doctype html>
	<html lang="en">
	<head>
	<meta charset="utf-8">
	<meta name="viewport" content="width=device-width,initial-scale=1">
	<link rel="stylesheet" type="text/css" href="%sstyle.css">
	<title>${TITLE}</title>
	</head>
	<body>
	<header>\n" $link_prefix\
	> $build_target
	
	echo '<div class=banner>' >> $build_target

	printf "<a href=%sindex.html>" $link_prefix >> $build_target

	add_figlet $build_target 

	echo '</a>' >> $build_target

	echo '</div>' >> $build_target
	
	printf '
	</header>\n'\
	>> $build_target 
	
	add_navbar $build_target $link_prefix
}


build_page () {
TARGET_FILE=${1}
SOURCE_FILE=${2}
BUILD_TARGET=${TARGET_DIR}/${TARGET_FILE}
BUILD_SOURCE=${TARGET_DIR}/content/${SOURCE_FILE}

add_header ${BUILD_TARGET}

printf '
<div class="column middle">
<div class="row">'\
>> "${BUILD_TARGET}" 

if [ -e ${BUILD_SOURCE} ]; then
	cat "${BUILD_SOURCE}" >> "${BUILD_TARGET}"
fi

printf '
</div>
</div>\n'\
>> "${BUILD_TARGET}"

add_footer "${BUILD_TARGET}"

printf "\
</body>
</html>\
" >> "${BUILD_TARGET}"

}

build_blog_post () {
local posts=$(ls $1)
LENGTH=${#BLOG_DIR} 
LENGTH=$(( LENGTH + 1 )) 
for i in ${posts}; do
	path=${i%.*} # remove .md
	tmpfile=$path.tmp
	title=$(echo "$path" | cut -c ${LENGTH}-) # keep only title
	printf 'Blog post \"%s\" ' "$title"
	titlef=$(echo $title | cut -d $'_' -f2 | sed 's/-/\ /g') # replace dashes with space
	datef=$(echo $title | cut -d $'_' -f1 ) # replace dashes with space
	datef=$(date -d $datef +'%B %d, %Y')
	printf '<p><small>%s</small></p>\n' "$datef" > $tmpfile
	cat $i >> $tmpfile 
	sed -i "2s/^/## $titlef\n/" $tmpfile # add title on first line
	# add dinkus and posted date
	printf '<br><br><p><center><small><pre>* * *</pre></small></center></p>\n' "$datef" >> $tmpfile
	pandoc $tmpfile --from markdown --to html --output $tmpfile.html
	build_blog_page $path.html $tmpfile.html '../'
	rm -f $tmpfile $tmpfile.html
	printf '... Done\n'
done
}

build_blog_archive () {
	BLOG_DIR="${TARGET_DIR}/blog/"
	> $BLOG_DIR/.archive
	POSTS=$(ls -r $BLOG_DIR*.md)
	LENGTH=${#BLOG_DIR} 
	LENGTH=$(expr $LENGTH + 1) 
	for i in $POSTS; do
	    j=${i%.*} # remove .md
	    j=$(echo "$j" | cut -c ${LENGTH}-)
	    k="$j.html"
		# cut out and format date
		datef=$(echo $j | cut -d '_' -f1)
		datef=$(date -d $datef +'%b %d %Y')
		# cut out title
		title=$(echo $j | cut -d '_' -f2)
	    title=$(echo "$title" | sed 's/-/\ /g')
	    #title=$(echo "$title" | sed 's/_/\ \&mdash;\ /g')
	    # make hyperlink
	    echo "<a href='blog/$k'>$datef - $title</a><br>" >> $BLOG_DIR/.archive
	done
}

build_blog_page () {
	local BUILD_TARGET=${1}
	local BUILD_SOURCE=${2}
	local link_prefix=${3}

	add_header "${BUILD_TARGET}" $link_prefix 

	printf '
	<div class="column middle">
	<div class="row">'\
	>> "${BUILD_TARGET}" 

	cat $BUILD_SOURCE >> "${BUILD_TARGET}"

	printf '
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
	init destination 
	build destination"
}

case $1 in
	init)
		init
		source_metadata
		exit 1
		;;
	build)
		echo "Building ..."
		source_metadata
		build_page index.html home_text
       	build_blog_archive
       	build_blog_post "${TARGET_DIR}/blog/*.md"
		build_blog_page ${TARGET_DIR}/blog.html ${TARGET_DIR}/blog/.archive ''
		get_size $TARGET_DIR
		build_page about.html about_text 
		get_size $TARGET_DIR
		echo "Build completed."
		echo "Total build size: $SIZE kB"
		exit 1
		;;
	*)
		help
		exit 1
		;;
esac
