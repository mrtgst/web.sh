#!/bin/bash
VERSION=0.2.14
ROOT=$2
TITLE=${0:2}
CONTENT_DIR=${ROOT}/content
BLOG_CONTENT_DIR=${ROOT}/content/blog
BLOG_DIR=${ROOT}/blog
CURRENT_YEAR=$(date +"%Y")
CURRENT_DATE=$(date +"%Y-%m-%d")
PREVIEW_DIR=${BLOG_CONTENT_DIR}/previews

get_size () {
	# gets size in kB
	SIZE=$(du -b $1 | tail -n1 | cut -d $'\t' -f1)
	SIZE=$(( SIZE / 1000 ))
}

add_blog_post () {
	local blog_title=$1
	local blog_text=$2
	# format blog title
	blog_titlef=$(echo ${blog_title} | tr A-Z a-z)
	blog_titlef=$(echo $blog_titlef | sed 's/\ /-/g') # replace space with dash 
	blog_titlef=${CURRENT_DATE}_${blog_titlef}
	blog_file=${BLOG_CONTENT_DIR}/$blog_titlef.md
	touch "$blog_file"
	printf "## $blog_title\n\n\n" > $blog_file
	printf "$blog_text" >> $blog_file
}

edit_blog_post () {
	#if [ -v $EDITOR ]; then 
	#	echo "No default editor found, enter name of your editor: "
	#	EDITOR=$(read)
	#fi
	local blog_title=$@
	# format blog title
	blog_titlef=$(echo ${blog_title} | tr A-Z a-z)
	blog_titlef=$(echo $blog_titlef | sed 's/\ /-/g') # replace space with dash 
	blog_titlef=${CURRENT_DATE}_${blog_titlef}
	blog_file=${BLOG_CONTENT_DIR}/$blog_titlef.md
	touch "$blog_file"
	printf "## $blog_title\n\n\n" > $blog_file
	#${EDITOR} $blog_file 
	vim $blog_file 
}

init () {
	# initiate template files
	if ! [ -d ${CONTENT_DIR} ]; then mkdir -p ${CONTENT_DIR}; fi
	if ! [ -d ${BLOG_CONTENT_DIR} ]; then 
		mkdir -p ${BLOG_CONTENT_DIR}
		# add template blog post if no posts exist
		if ! [ $(ls -A ${BLOG_CONTENT_DIR}) ]; then
			add_blog_post "Blog title" "You can use *markdown* syntax to **typeset** your posts.\n\n### Subheaders are allowed\n If you want to use them." 
		fi
	fi
	if ! [ -d ${BLOG_DIR} ]; then 
		mkdir -p ${BLOG_DIR}  
	fi
	if ! [ -e ${CONTENT_DIR}/home_text ]; then echo "Welcome to ${TITLE}" > ${CONTENT_DIR}/home_text; fi
	if ! [ -e ${CONTENT_DIR}/about_text ]; then echo "Something about ${TITLE}" > ${CONTENT_DIR}/about_text; fi

	# write to metadata file
	if ! [ -e ${CONTENT_DIR}/metadata ]; then
		printf "# these variables contain the site metadata
		# edit them to fit your site\n
		TITLE=%s
		FIGLET_TITLE_TEXT=%s
		FIGLET_FONT='small'
		" ${TITLE} ${TITLE} > ${CONTENT_DIR}/metadata
		echo "Wrote ${CONTENT_DIR}/metadata file"
	fi

	# copy stylesheet
	cp ./style.css ${ROOT} 
}

source_metadata () {
	# source metadata file
	. ${CONTENT_DIR}/metadata
}


add_figlet () {
	figlet -f small -w 1080 "${FIGLET_TITLE_TEXT}" >> "$1"
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
	BUILD_TARGET=${ROOT}/${TARGET_FILE}
	BUILD_SOURCE=${CONTENT_DIR}/${SOURCE_FILE}
	
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

build_preview_page () {
	TARGET_FILE=${1}
	SOURCE_FILE=${2}
	BUILD_TARGET=${ROOT}/${TARGET_FILE}
	BUILD_SOURCE=${CONTENT_DIR}/${SOURCE_FILE}
	
	add_header ${BUILD_TARGET}
	
	printf '
	<div class="column middle">
	<div class="row">'\
	>> "${BUILD_TARGET}" 
	
	previews=$(ls -r $PREVIEW_DIR)
	for i in ${previews}; do
		cat "${PREVIEW_DIR}/$i" >> "${BUILD_TARGET}"
	done	
	
	printf '
	</div>
	</div>\n'\
	>> "${BUILD_TARGET}"
	
	add_footer "${BUILD_TARGET}"
	
	printf "\
	</body>
	</html>\
	" >> "${BUILD_TARGET}"
	
	# remove preview directory when done
	rm -rf ${PREVIEW_DIR}
}

build_blog_post () {
	# clear existing posts
	printf "Clearing existing blog posts ... "
	rm -f ${BLOG_DIR}/*.html
	printf "Done\n"
	local posts=$(ls $1)
	local length=${#BLOG_CONTENT_DIR} 
	length=$(( length + 2 )) 
	for i in ${posts}; do
		path=${i%.*} # remove .md
		tmpfile=$path.tmp
		filename=$(echo "$path" | cut -c ${length}-) # keep only filename 
		mkdir -p ${BLOG_CONTENT_DIR}/previews
		tmpfile_preview=${BLOG_CONTENT_DIR}/previews/${filename}_preview
		printf 'Building blog post \"%s\" ' "$filename"


		# cut out the first n words
		#preview_n=50
		#preview_text=$(grep -v '##' $i | tr --delete '\n' | cut -d ' ' -f 1-${preview_n})

		# convert to html 
		cmark --smart --to html $i > $tmpfile.html
		cmark --smart --to html $i > $tmpfile_preview.html

		# grab title from first line
		preview_title=$(head -n1 $i | sed 's/#//g')
		printf "<div class="preview"><a href='%s'><h2>%s</h2></a></div>" "blog/${filename}.html" "${preview_title}" >> $tmpfile_preview
		echo "$preview_text" >> $tmpfile_preview
		printf '... ' >> $tmpfile_preview
		printf '<a href='%s'>Read more</a>' "blog/${filename}.html" >> $tmpfile_preview

		# convert to html 
		cmark --smart --to html $i > $tmpfile.html
		cmark --smart --to html $i > $tmpfile_preview.html

		# add post date to top of blog post
		datef=$(echo $filename | cut -d $'_' -f1 ) # replace dashes with space
		datef=$(date -d ${datef} +'%B %d, %Y')
		sed -i "1i ${datef}" $tmpfile.html
		sed -i "1i ${datef}" $tmpfile_preview.html

		# add dinkus to bottom of blog post
		printf '<p><center>&#8258;</center></p>\n' "${datef}" >> $tmpfile.html
		printf '<br><p><center>&#8258;</center></p><br><br>\n' "${datef}" >> $tmpfile_preview.html

		## make title link in preview
		#preview_title=$(head -n1 $i | sed 's/#//g') # grab title from first line
		#printf "<div class="preview"><a href='%s'><h2>%s</h2></a></div>" "blog/${filename}.html" "${preview_title}" >> $tmpfile_preview.html
		##printf '... ' >> $tmpfile_preview
		##printf '<a href='%s'>Read more</a>' "blog/${filename}.html" >> $tmpfile_preview
		# build blog post page
		build_blog_page $path.html $tmpfile.html '../'
		mv $path.html ${BLOG_DIR}/$filename.html

		# remove temporary files
		rm -f $tmpfile $tmpfile.html
		rm -f $tmpfile_preview
		printf '... Done\n'
	done
}

build_blog_archive () {
	# makes a file .archive with a list of all blog posts as hrefs
	> ${BLOG_CONTENT_DIR}/.archive
	POSTS=$(ls -r ${BLOG_CONTENT_DIR}/*.md)
	length=${#BLOG_CONTENT_DIR} 
	length=$(( $length + 2))

	for i in $POSTS; do
	    j=${i%.*} # remove .md
	    j=$(echo "$j" | cut -c ${length}-)
	    k="$j.html"

		# cut out and format date
		datef=$(echo $j | cut -d '_' -f1)
		datef=$(date -d ${datef} +'%b %d, %Y')

		# get title from first line in md file
		title=$(head -n1 $i | sed 's/##//g' | sed 's/^\ //g')

	    # make hyperlink
	    echo "<a href='blog/$k'>${datef} - $title</a><br>" >> ${BLOG_CONTENT_DIR}/.archive
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
	build [site root dir]
	blog [site root dir] 'Blog title'"
}

build () {
	local root=$1
	echo "Building in directory ${root}"
	init
	source_metadata
	#build_page index.html home_text
   	build_blog_archive
	build_blog_post "${BLOG_CONTENT_DIR}/*.md"
	build_blog_page ${ROOT}/blog.html ${ROOT}/content/blog/.archive ''
	build_preview_page index.html ${PREVIEW_DIR} ''
	get_size ${ROOT}
	build_page about.html about_text 
	get_size ${ROOT}
	echo "Build completed"
	echo "Total build size: $SIZE kB"
}

case $1 in
	build)
		build ${ROOT}
		exit 1
		;;
	blog)
		edit_blog_post $3
		exit 1
		;;
	*)
		help
		exit 1
		;;
esac
