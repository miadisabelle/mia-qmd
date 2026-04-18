TLID=$(tlid min)

for q in \
	"workflow EAST practice of gathering the intentions and preparing the internal and external inquiries" \
	"workflow for EAST practice in ceremonial technology development" \
	"intention preparation in ceremonial technology development" \
	"grounding the intentions" \
	"grounding the intention into an adequate format that draw an adequate format for working with them with users during a ceremony"
do 
	fn=$(mksafefilename "$q")
	echo "## $q" |tee $fn.md
	echo "  ">> $fn.md
	qmd search "$q" |tee -a $fn.md

done |tee inquiry-$TLID.md

