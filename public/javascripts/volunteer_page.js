$(function(){
	$("#skills").superblyTagField({
		  allowNewTags: true,
		  showTagsNumber: 10,
		  preset: getHtmls($('#volSkills li')),
		  tags: getHtmls($('#allSkills li'))
	});
});

function getHtmls(obj) {
	var ret = [];
	obj.each(function(){ret.push($(this).html());});
	return ret;
}
