#!/usr/bin/perl -w

BEGIN { # CPAN users don't have ME::*, so use eval
  eval 'use ME::FindLibs'
}

use Test::More tests => 253;
use HTML::Defang;

use strict;
use warnings;

my ($R, $H);
my ($DefangString, $CommentStartText, $CommentEndText) = ('defang_', ' ', ' ');

my $D = HTML::Defang->new();

#	$H = <<EOF;
#	';alert(String.fromCharCode(88,83,83))//\';alert(String.fromCharCode(88,83,83))//";alert(String.fromCharCode(88,83,83))//\";alert(String.fromCharCode(88,83,83))//--></SCRIPT>">'><SCRIPT>alert(String.fromCharCode(88,83,83))</SCRIPT>
#	EOF
#	$R = $D->defang($H);
#	like($R, qr{^$}, "XSS locator - XXX JS injection");

#	$H = <<EOF;
#	'';!--"<XSS>=&{()}
#	EOF
#	$R = $D->defang($H);
#	like($R, qr{^$}, "XSS locator 2 - XXX JS injection");

$H = <<EOF;
<SCRIPT SRC=http://ha.ckers.org/xss.js></SCRIPT>
EOF
$R = $D->defang($H);
like($R, qr{^<!--${DefangString}SCRIPT SRC=http://ha.ckers.org/xss.js--><!--${CommentStartText}${CommentEndText}--><!--/${DefangString}SCRIPT-->$}, "No filter evasion");

$H = <<EOF;
<IMG SRC="javascript:alert('XSS');">
EOF
$R = $D->defang($H);
like($R, qr{^<IMG defang_SRC="javascript:alert\('XSS'\);">$}, "Image XSS using the JavaScript directive");

$H = <<EOF;
<IMG SRC=javascript:alert('XSS')>
EOF
$R = $D->defang($H);
like($R, qr{^<IMG defang_SRC=javascript:alert\(&apos;XSS&apos;\)>$}, "No quotes and no semicolon");

$H = <<EOF;
<IMG SRC=JaVaScRiPt:alert('XSS')>
EOF
$R = $D->defang($H);
like($R, qr{^<IMG defang_SRC=JaVaScRiPt:alert\(&apos;XSS&apos;\)>$}, "Case insensitive XSS attack vector");

$H = <<EOF;
<IMG SRC=javascript:alert(&quot;XSS&quot;)>
EOF
$R = $D->defang($H);
like($R, qr{^<IMG defang_SRC=javascript:alert\(&quot;XSS&quot;\)>$}, "HTML entities");

$H = <<EOF;
<IMG SRC=`javascript:alert("RSnake says, 'XSS'")`>
EOF
$R = $D->defang($H);
like($R, qr{^<IMG defang_SRC="javascript:alert\(&quot;RSnake says, 'XSS'&quot;\)">$}, "Grave accent obfuscation");

$H = <<EOF;
<IMG """><SCRIPT>alert("XSS")</SCRIPT>">
EOF
$R = $D->defang($H);
like($R, qr{^<IMG defang_"""><!--${DefangString}SCRIPT--><!--${CommentStartText}alert\("XSS"\)${CommentEndText}--><!--/${DefangString}SCRIPT-->">$}, "Malformed IMG tags - XXX Check defang_ added around quotes");

$H = <<EOF;
<IMG SRC=javascript:alert(String.fromCharCode(88,83,83))>
EOF
$R = $D->defang($H);
like($R, qr{^<IMG defang_SRC=javascript:alert\(String.fromCharCode\(88,83,83\)\)>$}, "fromCharCode");

$H = <<EOF;
<IMG SRC=&#106;&#97;&#118;&#97;&#115;&#99;&#114;&#105;&#112;&#116;&#58;&#97;&#108;&#101;&#114;&#116;&#40;&#39;&#88;&#83;&#83;&#39;&#41;>
EOF
$R = $D->defang($H);
like($R, qr{^<IMG defang_SRC=javascript:alert\(&apos;XSS&apos;\)>$}, "UTF-8 Unicode encoding");

$H = <<EOF;
<IMG SRC=&#0000106&#0000097&#0000118&#0000097&#0000115&#0000099&#0000114&#0000105&#0000112&#0000116&#0000058&#0000097&#0000108&#0000101&#0000114&#0000116&#0000040&#0000039&#0000088&#0000083&#0000083&#0000039&#0000041>
EOF
$R = $D->defang($H);
like($R, qr{^<IMG defang_SRC=javascript:alert\(&apos;XSS&apos;\)>$}, "Long UTF-8 Unicode encoding without semicolons");

$H = <<EOF;
<IMG SRC=&#x6A&#x61&#x76&#x61&#x73&#x63&#x72&#x69&#x70&#x74&#x3A&#x61&#x6C&#x65&#x72&#x74&#x28&#x27&#x58&#x53&#x53&#x27&#x29>
EOF
$R = $D->defang($H);
like($R, qr{^<IMG defang_SRC=javascript:alert\(&apos;XSS&apos;\)>$}, "Hex encoding without semicolons");

$H = <<EOF;
<IMG SRC="jav	ascript:alert('XSS');">
EOF
$R = $D->defang($H);
like($R, qr{^<IMG defang_SRC="jav&#x09;ascript:alert\('XSS'\);">$}, "Embedded tab to break up the cross site scripting attack");

$H = <<EOF;
<IMG SRC="jav&#x09;ascript:alert('XSS');">
EOF
$R = $D->defang($H);
like($R, qr{^<IMG defang_SRC="jav&#x09;ascript:alert\('XSS'\);">$}, "Embedded encoded tab to break up XSS:");

$H = <<EOF;
<IMG SRC="jav&#x0A;ascript:alert('XSS');">
EOF
$R = $D->defang($H);
like($R, qr{^<IMG defang_SRC="jav&#x0a;ascript:alert\('XSS'\);">$}, "Embeded newline to break up XSS");

$H = <<EOF;
<IMG SRC="jav&#x0D;ascript:alert('XSS');">
EOF
$R = $D->defang($H);
like($R, qr{^<IMG defang_SRC="javascript:alert\('XSS'\);">$}, "Embedded carriage return to break up XSS");

$H = <<EOF;
<IMG
SRC
=
"
j
a
v
a
s
c
r
i
p
t
:
a
l
e
r
t
(
'
X
S
S
'
)
"
>
EOF
$R = $D->defang($H);
like($R, qr{^<IMG\sdefang_SRC\s=\s"&#x0a;j&#x0a;a&#x0a;v&#x0a;a&#x0a;s&#x0a;c&#x0a;r&#x0a;i&#x0a;p&#x0a;t&#x0a;:&#x0a;a&#x0a;l&#x0a;e&#x0a;r&#x0a;t&#x0a;\(&#x0a;'&#x0a;X&#x0a;S&#x0a;S&#x0a;'&#x0a;\)&#x0a;"\s>\s$}, "Multiline Injected JavaScript using ASCII carriage returns");

$H = <<EOF;
<IMG SRC=java script:alert('XSS')>
EOF
$R = $D->defang($H);
like($R, qr{^<IMG defang_SRC=javascript:alert\(&apos;XSS&apos;\)>$}, "Null breaks up JavaScript directive");

$H = <<EOF;
<SCR IPT>alert("XSS")</SCR IPT>
EOF
$R = $D->defang($H);
like($R, qr{^<!--${DefangString}SCRIPT--><!--${CommentStartText}alert\("XSS"\)${CommentEndText}--><!--/${DefangString}SCRIPT-->}, "Null breaks up cross site scripting vector");

$H = <<EOF;
<IMG SRC=" &#14;  javascript:alert('XSS');">
EOF
$R = $D->defang($H);
like($R, qr{^<IMG defang_SRC="   javascript:alert\('XSS'\);">$}, "Spaces and meta chars before the JavaScript in images for XSS");

$H = <<EOF;
<IMG SRC="data:text\/html,<script>alert('XSS');<\/script>">
EOF
$R = $D->defang($H);
like($R, qr{^<IMG defang_SRC="data:text\/html,&lt;script&gt;alert\('XSS'\);&lt;\/script&gt;">$}, "data: URL with text\/html content");

$H = <<EOF;
<SCRIPT/XSS SRC="http://ha.ckers.org/xss.js"></SCRIPT>
EOF
$R = $D->defang($H);
like($R, qr{^<!--${DefangString}SCRIPT/XSS SRC="http://ha.ckers.org/xss.js"--><!--${CommentStartText}${CommentEndText}--><!--/${DefangString}SCRIPT-->$}, "Non-alpha-non-digit XSS");

$H = <<'EOF';
<BODY onload!#$%&()*~+-_.,:;?@[/|\]^`=alert("XSS")>
EOF
$R = $D->defang($H);
like($R, qr{^<BODY defang_onload!#\$\%&\(\)\*~\+-_\.,:;\?\@\[/|\\\]\^`=alert\("XSS"\)>$}, "Non-alpha-non-digit part 2 XSS");

$H = <<EOF;
<SCRIPT/SRC="http://ha.ckers.org/xss.js"></SCRIPT>
EOF
$R = $D->defang($H);
like($R, qr{^<!--${DefangString}SCRIPT/SRC="http://ha.ckers.org/xss.js"--><!--${CommentStartText}${CommentEndText}--><!--/${DefangString}SCRIPT-->$}, "Non-alpha-non-digit part 3 XSS");

$H = <<EOF;
<<SCRIPT>alert("XSS");//<</SCRIPT>
EOF
$R = $D->defang($H);
like($R, qr{^<!--${DefangString}SCRIPT--><!--${CommentStartText}alert\("XSS"\);//<${CommentEndText}--><!--/${DefangString}SCRIPT-->$}, "Extraneous open brackets");

$H = <<EOF;
<SCRIPT SRC=http://ha.ckers.org/xss.js?<B>
EOF
$R = $D->defang($H);
like($R, qr{^<!--${DefangString}SCRIPT SRC=http://ha.ckers.org/xss.js\?<B-->$}, "No closing script tags");

$H = <<EOF;
<SCRIPT SRC=//ha.ckers.org/.j>
EOF
$R = $D->defang($H);
like($R, qr{^<!--${DefangString}SCRIPT SRC=//ha.ckers.org/.j-->$}, "Protocol resolution in script tags");

$H = <<EOF;
<IMG SRC="javascript:alert('XSS')"
EOF
$R = $D->defang($H);
like($R, qr{^<IMG defang_SRC="javascript:alert\('XSS'\)"\s>$}, "Half open HTML/JavaScript XSS vector");

$H = <<EOF;
<iframe src=http://ha.ckers.org/scriptlet.html <
EOF
$R = $D->defang($H);
like($R, qr{^<!--${DefangString}iframe defang_src=http:&#x2f;&#x2f;ha.ckers.org&#x2f;scriptlet.html -->$}, "Double open angle brackets");

$H = <<EOF;
<SCRIPT>a=/XSS/
alert(a.source)</SCRIPT>
EOF
$R = $D->defang($H);
like($R, qr{^<!--${DefangString}SCRIPT--><!--${CommentStartText}a=/XSS/\salert\(a.source\)${CommentEndText}--><!--/${DefangString}SCRIPT-->$}, "XSS with no single quotes or double quotes or semicolons");

#	$H = <<EOF;
#	\";alert('XSS');//
#	EOF
#	$R = $D->defang($H);
#	like($R, qr{^$}, "Escaping JavaScript escapes - XXX JS injection");

$H = <<EOF;
</TITLE><SCRIPT>alert("XSS");</SCRIPT>
EOF
$R = $D->defang($H);
like($R, qr{^</TITLE><!--${DefangString}SCRIPT--><!--||--/*SC*/ alert\("XSS"\); /*EC*/--||--><!--/${DefangString}SCRIPT-->$}, "End title tag");

$H = <<EOF;
<INPUT TYPE="IMAGE" SRC="javascript:alert('XSS');">
EOF
$R = $D->defang($H);
like($R, qr{^<INPUT TYPE="IMAGE" defang_SRC="javascript:alert\('XSS'\);">$}, "INPUT image");

$H = <<EOF;
<BODY BACKGROUND="javascript:alert('XSS')">
EOF
$R = $D->defang($H);
like($R, qr{^<BODY defang_BACKGROUND="javascript:alert\('XSS'\)">$}, "BODY image");

$H = <<EOF;
<BODY ONLOAD=alert('XSS')>
EOF
$R = $D->defang($H);
like($R, qr{^<BODY defang_ONLOAD=alert\(&apos;XSS&apos;\)>$}, "BODY tag");

$H = <<EOF;
1:<img FSCommand="someFunction()">
2:<img onAbort="someFunction()">
3:<img onActivate="someFunction()">
4:<img onAfterPrint="someFunction()">
5:<img onAfterUpdate="someFunction()">
6:<img onBeforeActivate="someFunction()">
7:<img onBeforeCopy="someFunction()">
8:<img onBeforeCut="someFunction()">
9:<img onBeforeDeactivate="someFunction()">
10:<img onBeforeEditFocus="someFunction()">
11:<img onBeforePaste="someFunction()">
12:<img onBeforePrint="someFunction()">
13:<img onBeforeUnload="someFunction()">
14:<img onBegin="someFunction()">
15:<img onBlur="someFunction()">
16:<img onBounce="someFunction()">
17:<img onCellChange="someFunction()">
18:<img onChange="someFunction()">
19:<img onClick="someFunction()">
20:<img onContextMenu="someFunction()">
21:<img onControlSelect="someFunction()">
22:<img onCopy="someFunction()">
23:<img onCut="someFunction()">
24:<img onDataAvailable="someFunction()">
25:<img onDataSetChanged="someFunction()">
26:<img onDataSetComplete="someFunction()">
27:<img onDblClick="someFunction()">
28:<img onDeactivate="someFunction()">
29:<img onDrag="someFunction()">
30:<img onDragEnd="someFunction()">
31:<img onDragLeave="someFunction()">
32:<img onDragEnter="someFunction()">
33:<img onDragOver="someFunction()">
34:<img onDragDrop="someFunction()">
35:<img onDrop="someFunction()">
36:<img onEnd="someFunction()">
37:<img onError="someFunction()">
38:<img onErrorUpdate="someFunction()">
39:<img onFilterChange="someFunction()">
40:<img onFinish="someFunction()">
41:<img onFocus="someFunction()">
42:<img onFocusIn="someFunction()">
43:<img onFocusOut="someFunction()">
44:<img onHelp="someFunction()">
45:<img onKeyDown="someFunction()">
46:<img onKeyPress="someFunction()">
47:<img onKeyUp="someFunction()">
48:<img onLayoutComplete="someFunction()">
49:<img onLoad="someFunction()">
50:<img onLoseCapture="someFunction()">
51:<img onMediaComplete="someFunction()">
52:<img onMediaError="someFunction()">
53:<img onMouseDown="someFunction()">
54:<img onMouseEnter="someFunction()">
55:<img onMouseLeave="someFunction()">
56:<img onMouseMove="someFunction()">
57:<img onMouseOut="someFunction()">
58:<img onMouseOver="someFunction()">
59:<img onMouseUp="someFunction()">
60:<img onMouseWheel="someFunction()">
61:<img onMove="someFunction()">
62:<img onMoveEnd="someFunction()">
63:<img onMoveStart="someFunction()">
64:<img onOutOfSync="someFunction()">
65:<img onPaste="someFunction()">
66:<img onPause="someFunction()">
67:<img onProgress="someFunction()">
68:<img onPropertyChange="someFunction()">
69:<img onReadyStateChange="someFunction()">
70:<img onRepeat="someFunction()">
71:<img onReset="someFunction()">
72:<img onResize="someFunction()">
73:<img onResizeEnd="someFunction()">
74:<img onResizeStart="someFunction()">
75:<img onResume="someFunction()">
76:<img onReverse="someFunction()">
77:<img onRowsEnter="someFunction()">
78:<img onRowExit="someFunction()">
79:<img onRowDelete="someFunction()">
80:<img onRowInserted="someFunction()">
81:<img onScroll="someFunction()">
82:<img onSeek="someFunction()">
83:<img onSelect="someFunction()">
84:<img onSelectionChange="someFunction()">
85:<img onSelectStart="someFunction()">
86:<img onStart="someFunction()">
87:<img onStop="someFunction()">
88:<img onSyncRestored="someFunction()">
89:<img onSubmit="someFunction()">
90:<img onTimeError="someFunction()">
91:<img onTrackChange="someFunction()">
92:<img onUnload="someFunction()">
93:<img onURLFlip="someFunction()">
94:<img seekSegmentTime="someFunction()">
EOF
$R = $D->defang($H);
like($R, qr{1:<img defang_FSCommand="someFunction\(\)">}, "FSCommand");
like($R, qr{2:<img defang_onAbort="someFunction\(\)">}, "onAbort");
like($R, qr{3:<img defang_onActivate="someFunction\(\)">}, "onActivate");
like($R, qr{4:<img defang_onAfterPrint="someFunction\(\)">}, "onAfterPrint");
like($R, qr{5:<img defang_onAfterUpdate="someFunction\(\)">}, "onAfterUpdate");
like($R, qr{6:<img defang_onBeforeActivate="someFunction\(\)">}, "onBeforeActivate");
like($R, qr{7:<img defang_onBeforeCopy="someFunction\(\)">}, "onBeforeCopy");
like($R, qr{8:<img defang_onBeforeCut="someFunction\(\)">}, "onBeforeCut");
like($R, qr{9:<img defang_onBeforeDeactivate="someFunction\(\)">}, "onBeforeDeactivate");
like($R, qr{10:<img defang_onBeforeEditFocus="someFunction\(\)">}, "onBeforeEditFocus");
like($R, qr{11:<img defang_onBeforePaste="someFunction\(\)">}, "onBeforePaste");
like($R, qr{12:<img defang_onBeforePrint="someFunction\(\)">}, "onBeforePrint");
like($R, qr{13:<img defang_onBeforeUnload="someFunction\(\)">}, "onBeforeUnload");
like($R, qr{14:<img defang_onBegin="someFunction\(\)">}, "onBegin");
like($R, qr{15:<img defang_onBlur="someFunction\(\)">}, "onBlur");
like($R, qr{16:<img defang_onBounce="someFunction\(\)">}, "onBounce");
like($R, qr{17:<img defang_onCellChange="someFunction\(\)">}, "onCellChange");
like($R, qr{18:<img defang_onChange="someFunction\(\)">}, "onChange");
like($R, qr{19:<img defang_onClick="someFunction\(\)">}, "onClick");
like($R, qr{20:<img defang_onContextMenu="someFunction\(\)">}, "onContextMenu");
like($R, qr{21:<img defang_onControlSelect="someFunction\(\)">}, "onControlSelect");
like($R, qr{22:<img defang_onCopy="someFunction\(\)">}, "onCopy");
like($R, qr{23:<img defang_onCut="someFunction\(\)">}, "onCut");
like($R, qr{24:<img defang_onDataAvailable="someFunction\(\)">}, "onDataAvailable");
like($R, qr{25:<img defang_onDataSetChanged="someFunction\(\)">}, "onDataSetChanged");
like($R, qr{26:<img defang_onDataSetComplete="someFunction\(\)">}, "onDataSetComplete");
like($R, qr{27:<img defang_onDblClick="someFunction\(\)">}, "onDblClick");
like($R, qr{28:<img defang_onDeactivate="someFunction\(\)">}, "onDeactivate");
like($R, qr{29:<img defang_onDrag="someFunction\(\)">}, "onDrag");
like($R, qr{30:<img defang_onDragEnd="someFunction\(\)">}, "onDragEnd");
like($R, qr{31:<img defang_onDragLeave="someFunction\(\)">}, "onDragLeave");
like($R, qr{32:<img defang_onDragEnter="someFunction\(\)">}, "onDragEnter");
like($R, qr{33:<img defang_onDragOver="someFunction\(\)">}, "onDragOver");
like($R, qr{34:<img defang_onDragDrop="someFunction\(\)">}, "onDragDrop");
like($R, qr{35:<img defang_onDrop="someFunction\(\)">}, "onDrop");
like($R, qr{36:<img defang_onEnd="someFunction\(\)">}, "onEnd");
like($R, qr{37:<img defang_onError="someFunction\(\)">}, "onError");
like($R, qr{38:<img defang_onErrorUpdate="someFunction\(\)">}, "onErrorUpdate");
like($R, qr{39:<img defang_onFilterChange="someFunction\(\)">}, "onFilterChange");
like($R, qr{40:<img defang_onFinish="someFunction\(\)">}, "onFinish");
like($R, qr{41:<img defang_onFocus="someFunction\(\)">}, "onFocus");
like($R, qr{42:<img defang_onFocusIn="someFunction\(\)">}, "onFocusIn");
like($R, qr{43:<img defang_onFocusOut="someFunction\(\)">}, "onFocusOut");
like($R, qr{44:<img defang_onHelp="someFunction\(\)">}, "onHelp");
like($R, qr{45:<img defang_onKeyDown="someFunction\(\)">}, "onKeyDown");
like($R, qr{46:<img defang_onKeyPress="someFunction\(\)">}, "onKeyPress");
like($R, qr{47:<img defang_onKeyUp="someFunction\(\)">}, "onKeyUp");
like($R, qr{48:<img defang_onLayoutComplete="someFunction\(\)">}, "onLayoutComplete");
like($R, qr{49:<img defang_onLoad="someFunction\(\)">}, "onLoad");
like($R, qr{50:<img defang_onLoseCapture="someFunction\(\)">}, "onLoseCapture");
like($R, qr{51:<img defang_onMediaComplete="someFunction\(\)">}, "onMediaComplete");
like($R, qr{52:<img defang_onMediaError="someFunction\(\)">}, "onMediaError");
like($R, qr{53:<img defang_onMouseDown="someFunction\(\)">}, "onMouseDown");
like($R, qr{54:<img defang_onMouseEnter="someFunction\(\)">}, "onMouseEnter");
like($R, qr{55:<img defang_onMouseLeave="someFunction\(\)">}, "onMouseLeave");
like($R, qr{56:<img defang_onMouseMove="someFunction\(\)">}, "onMouseMove");
like($R, qr{57:<img defang_onMouseOut="someFunction\(\)">}, "onMouseOut");
like($R, qr{58:<img defang_onMouseOver="someFunction\(\)">}, "onMouseOver");
like($R, qr{59:<img defang_onMouseUp="someFunction\(\)">}, "onMouseUp");
like($R, qr{60:<img defang_onMouseWheel="someFunction\(\)">}, "onMouseWheel");
like($R, qr{61:<img defang_onMove="someFunction\(\)">}, "onMove");
like($R, qr{62:<img defang_onMoveEnd="someFunction\(\)">}, "onMoveEnd");
like($R, qr{63:<img defang_onMoveStart="someFunction\(\)">}, "onMoveStart");
like($R, qr{64:<img defang_onOutOfSync="someFunction\(\)">}, "onOutOfSync");
like($R, qr{65:<img defang_onPaste="someFunction\(\)">}, "onPaste");
like($R, qr{66:<img defang_onPause="someFunction\(\)">}, "onPause");
like($R, qr{67:<img defang_onProgress="someFunction\(\)">}, "onProgress");
like($R, qr{68:<img defang_onPropertyChange="someFunction\(\)">}, "onPropertyChange");
like($R, qr{69:<img defang_onReadyStateChange="someFunction\(\)">}, "onReadyStateChange");
like($R, qr{70:<img defang_onRepeat="someFunction\(\)">}, "onRepeat");
like($R, qr{71:<img defang_onReset="someFunction\(\)">}, "onReset");
like($R, qr{72:<img defang_onResize="someFunction\(\)">}, "onResize");
like($R, qr{73:<img defang_onResizeEnd="someFunction\(\)">}, "onResizeEnd");
like($R, qr{74:<img defang_onResizeStart="someFunction\(\)">}, "onResizeStart");
like($R, qr{75:<img defang_onResume="someFunction\(\)">}, "onResume");
like($R, qr{76:<img defang_onReverse="someFunction\(\)">}, "onReverse");
like($R, qr{77:<img defang_onRowsEnter="someFunction\(\)">}, "onRowsEnter");
like($R, qr{78:<img defang_onRowExit="someFunction\(\)">}, "onRowExit");
like($R, qr{79:<img defang_onRowDelete="someFunction\(\)">}, "onRowDelete");
like($R, qr{80:<img defang_onRowInserted="someFunction\(\)">}, "onRowInserted");
like($R, qr{81:<img defang_onScroll="someFunction\(\)">}, "onScroll");
like($R, qr{82:<img defang_onSeek="someFunction\(\)">}, "onSeek");
like($R, qr{83:<img defang_onSelect="someFunction\(\)">}, "onSelect");
like($R, qr{84:<img defang_onSelectionChange="someFunction\(\)">}, "onSelectionChange");
like($R, qr{85:<img defang_onSelectStart="someFunction\(\)">}, "onSelectStart");
like($R, qr{86:<img defang_onStart="someFunction\(\)">}, "onStart");
like($R, qr{87:<img defang_onStop="someFunction\(\)">}, "onStop");
like($R, qr{88:<img defang_onSyncRestored="someFunction\(\)">}, "onSyncRestored");
like($R, qr{89:<img defang_onSubmit="someFunction\(\)">}, "onSubmit");
like($R, qr{90:<img defang_onTimeError="someFunction\(\)">}, "onTimeError");
like($R, qr{91:<img defang_onTrackChange="someFunction\(\)">}, "onTrackChange");
like($R, qr{92:<img defang_onUnload="someFunction\(\)">}, "onUnload");
like($R, qr{93:<img defang_onURLFlip="someFunction\(\)">}, "onURLFlip");
like($R, qr{94:<img defang_seekSegmentTime="someFunction\(\)">$}, "seekSegmentTime");

$H = <<EOF;
<IMG DYNSRC="javascript:alert('XSS')">
EOF
$R = $D->defang($H);
like($R, qr{^<IMG defang_DYNSRC="javascript:alert\('XSS'\)">$}, "IMG Dynsrc");

$H = <<EOF;
<IMG LOWSRC="javascript:alert('XSS')">
EOF
$R = $D->defang($H);
like($R, qr{^<IMG defang_LOWSRC="javascript:alert\('XSS'\)">$}, "IMG lowsrc");

$H = <<EOF;
<BGSOUND SRC="javascript:alert('XSS');">
EOF
$R = $D->defang($H);
like($R, qr{^<BGSOUND defang_SRC="javascript:alert\('XSS'\);">$}, "BGSOUND");

$H = <<EOF;
<BR SIZE="&\{alert\('XSS'\)\}">
EOF
$R = $D->defang($H);
like($R, qr{<BR defang_SIZE="&amp;\{alert\('XSS'\)\}">}, "& JavaScript includes (works in Netscape 4.x)");

$H = <<EOF;
<LAYER SRC="http://ha.ckers.org/scriptlet.html"></LAYER>
EOF
$R = $D->defang($H);
like($R, qr{^<!--${DefangString}LAYER defang_SRC="http://ha.ckers.org/scriptlet.html"--><!--/${DefangString}LAYER-->$}, "LAYER (also only works in Netscape 4.x)");

$H = <<EOF;
<LINK REL="stylesheet" HREF="javascript:alert('XSS');">
EOF
$R = $D->defang($H);
like($R, qr{^<!--${DefangString}LINK defang_REL="stylesheet" defang_HREF="javascript:alert\('XSS'\);"-->$}, "STYLE sheet");

$H = <<EOF;
<LINK REL="stylesheet" HREF="http://ha.ckers.org/xss.css">
EOF
$R = $D->defang($H);
like($R, qr{^<!--${DefangString}LINK defang_REL="stylesheet" defang_HREF="http://ha.ckers.org/xss.css"-->$}, "Remote style sheet");

$H = <<EOF;
<STYLE>\@import'http://ha.ckers.org/xss.css';</STYLE>
EOF
$R = $D->defang($H);
like($R, qr{^<STYLE><!--${CommentStartText}${CommentEndText}--></STYLE>$}, "Remote style sheet part 2 - XXX Style");

$H = <<EOF;
<META HTTP-EQUIV="Link" Content="<http://ha.ckers.org/xss.css>; REL=stylesheet">
EOF
$R = $D->defang($H);
like($R, qr{^<META defang_HTTP-EQUIV="Link" defang_Content="&lt;http://ha.ckers.org/xss.css&gt;; REL=stylesheet">$}, "Remote style sheet part 3");

$H = <<EOF;
<STYLE>BODY{-moz-binding:url("http://ha.ckers.org/xssmoz.xml#xss")}</STYLE>
EOF
$R = $D->defang($H);
like($R, qr{^<STYLE><!--${CommentStartText}BODY\{/\*-moz-binding:url\("http://ha.ckers.org/xssmoz.xml#xss"\)\*/\}${CommentEndText}--></STYLE>\s$}, "Remote style sheet part 4 - XXX Style");

$H = <<EOF;
<XSS STYLE="behavior: url(xss.htc);">
EOF
$R = $D->defang($H);
like($R, qr{^<!--${DefangString}XSS STYLE="/\*behavior: url\(xss.htc\);\*/"-->$}, "Local htc file");

$H = <<EOF;
<STYLE>li {list-style-image: url("javascript:alert('XSS')");}</STYLE><UL><LI>XSS
EOF
$R = $D->defang($H);
like($R, qr{^<STYLE><!--${CommentStartText}li \{/\*list-style-image: url\("javascript:alert\('XSS'\)"\);\*/\}${CommentEndText}--></STYLE><UL><LI>XSS$}, "List-style-image - XXX Style");

$H = <<EOF;
<IMG SRC='vbscript:msgbox("XSS")'>
EOF
$R = $D->defang($H);
like($R, qr{^<IMG defang_SRC='vbscript:msgbox\("XSS"\)'>$}, "VBscript in an image");

$H = <<EOF;
<IMG SRC="mocha:[code]">
EOF
$R = $D->defang($H);
like($R, qr{^<IMG defang_SRC="mocha:\[code\]">$}, "Mocha");

$H = <<EOF;
<IMG SRC="livescript:[code]">
EOF
$R = $D->defang($H);
like($R, qr{^<IMG defang_SRC="livescript:\[code\]">$}, "Livescript");

#	$H = <<EOF;
#	¼script¾alert(¢XSS¢)¼/script¾
#	EOF
#	$R = $D->defang($H);
#	like($R, qr{^$}, "US-ASCII encoding - XXX Weird chars above");

$H = <<EOF;
<META HTTP-EQUIV="refresh" CONTENT="0;url=javascript:alert('XSS');">
EOF
$R = $D->defang($H);
like($R, qr{^<META defang_HTTP-EQUIV="refresh" defang_CONTENT="0;url=javascript:alert\('XSS'\);">$}, "META");

$H = <<EOF;
<META HTTP-EQUIV="refresh" CONTENT="0;url=data:text/html;base64,PHNjcmlwdD5hbGVydCgnWFNTJyk8L3NjcmlwdD4K">
EOF
$R = $D->defang($H);
like($R, qr{^<META defang_HTTP-EQUIV="refresh" defang_CONTENT="0;url=data:text/html;base64,PHNjcmlwdD5hbGVydCgnWFNTJyk8L3NjcmlwdD4K">$}, "META using data: directive URL scheme");

$H = <<EOF;
<META HTTP-EQUIV="refresh" CONTENT="0; URL=http://;URL=javascript:alert('XSS');">
EOF
$R = $D->defang($H);
like($R, qr{^<META defang_HTTP-EQUIV="refresh" defang_CONTENT="0; URL=http://;URL=javascript:alert\('XSS'\);">$}, "META with additional URL parameter");

$H = <<EOF;
<IFRAME SRC="javascript:alert('XSS');"></IFRAME>
EOF
$R = $D->defang($H);
like($R, qr{^<!--${DefangString}IFRAME defang_SRC="javascript:alert\('XSS'\);"--><!--/${DefangString}IFRAME-->$}, "IFRAME");

$H = <<EOF;
<FRAMESET><FRAME SRC="javascript:alert('XSS');"></FRAMESET>
EOF
$R = $D->defang($H);
like($R, qr{^<!--${DefangString}FRAMESET--><!--${DefangString}FRAME defang_SRC="javascript:alert\('XSS'\);"--><!--/${DefangString}FRAMESET-->$}, "FRAME");

$H = <<EOF;
<TABLE BACKGROUND="javascript:alert('XSS')">
EOF
$R = $D->defang($H);
like($R, qr{^<TABLE defang_BACKGROUND="javascript:alert\('XSS'\)">$}, "TABLE");

$H = <<EOF;
<TABLE><TD BACKGROUND="javascript:alert('XSS')">
EOF
$R = $D->defang($H);
like($R, qr{^<TABLE><TD defang_BACKGROUND="javascript:alert\('XSS'\)">$}, "TD");

$H = <<EOF;
<DIV STYLE="background-image: url\(javascript:alert\('XSS'\)\)">
EOF
$R = $D->defang($H);
like($R, qr{^<DIV STYLE="/\*background-image: url\(javascript:alert\('XSS'\)\)\*/">$}, "DIV background-image - XXX Style attribute");

$H = <<EOF;
<DIV STYLE="background-image:\\0075\\0072\\006C\\0028'\\006a\\0061\\0076\\0061\\0073\\0063\\0072\\0069\\0070\\0074\\003a\\0061\\006c\\0065\\0072\\0074\\0028\\0027\\0058\\0053\\0053\\0027\\0029'\\0029">
EOF
$R = $D->defang($H);
like($R, qr{^<DIV STYLE="/\*background-image:url\('javascript:alert\('XSS'\)'\)\*/">$}, "DIV background-image with unicoded XSS exploit - XXX Style attribute");

$H = <<EOF;
<DIV STYLE="background-image: url(&#1;javascript:alert('XSS'))">
EOF
$R = $D->defang($H);
like($R, qr{^<DIV STYLE="/\*background-image: url\(javascript:alert\('XSS'\)\)\*/">$}, "DIV background-image plus extra characters - XXX Style attribute");

$H = <<EOF;
<DIV STYLE="width: expression(alert('XSS'));">
EOF
$R = $D->defang($H);
like($R, qr{^<DIV STYLE="/\*width: expression\(alert\('XSS'\)\);\*/">$}, "DIV expression - XXX Style attribute");

$H = <<EOF;
<STYLE>\@im\\port'\\ja\\vasc\\ript:alert("XSS")';</STYLE>
EOF
$R = $D->defang($H);
like($R, qr{^<STYLE><!--${CommentStartText}${CommentEndText}--></STYLE>$}, "STYLE tags with broken up JavaScript for XSS - XXX Style");

$H = <<EOF;
<IMG STYLE="xss:expr/*XSS*/ession(alert('XSS'))">
EOF
$R = $D->defang($H);
like($R, qr{^<IMG STYLE="/\*xss:expression\(alert\('XSS'\)\)\*/">$}, "STYLE attribute using a comment to break up expression - XXX Style attribute");

$H = <<EOF;
<XSS STYLE="xss:expression(alert('XSS'))">
EOF
$R = $D->defang($H);
like($R, qr{^<!--${DefangString}XSS STYLE="/\*xss:expression\(alert\('XSS'\)\)\*/"-->$}, "Anonymous HTML with STYLE attribute - XXX Style attribute");

#	$H = <<EOF;
#	exp/*<A STYLE='no\\xss:noxss("*//*");
#	xss:&#101;x&#x2F;*XSS*//*/*/pression(alert("XSS"))'>
#	EOF
#	$R = $D->defang($H);
#	like($R, qr{^$}, "IMG STYLE with expression - XXX Style attribute");

$H = <<EOF;
<STYLE TYPE="text/javascript">alert('XSS');</STYLE>
EOF
$R = $D->defang($H);
like($R, qr{^<STYLE defang_TYPE="text/javascript"><!--${CommentStartText}${CommentEndText}--></STYLE>$}, "STYLE tag - XXX Style");

$H = <<EOF;
<STYLE>.XSS{background-image:url("javascript:alert('XSS')");}</STYLE><A CLASS=XSS></A>
EOF
$R = $D->defang($H);
like($R, qr{^<STYLE><!--${CommentStartText}.XSS{/\*background-image:url\("javascript:alert\('XSS'\)"\);\*/}${CommentEndText}--></STYLE><A CLASS=XSS></A>$}, "STYLE tag using background-image - XXX Style");

$H = <<EOF;
<STYLE type="text/css">BODY{background:url("javascript:alert('XSS')")}</STYLE>
EOF
$R = $D->defang($H);
like($R, qr{^<STYLE type="text/css"><!--${CommentStartText}BODY\{/\*background:url\("javascript:alert\('XSS'\)"\)\*/\}${CommentEndText}--></STYLE>$}, "STYLE tag using background - XXX Style");

$H = <<EOF;
<!--[if gte IE 4]>
<SCRIPT>alert('XSS');</SCRIPT>
<![endif]-->
EOF
$R = $D->defang($H);
like($R, qr{^<!--/\*--\[if/SC\*/ gte IE 4]>\s<SCRIPT>alert\('XSS'\);</SCRIPT>\s/\*EC\*/<!\[endif\]--||-->$}, "Downlevel-Hidden block");

$H = <<EOF;
<BASE HREF="javascript:alert('XSS');//">
EOF
$R = $D->defang($H);
like($R, qr{^<BASE defang_HREF="javascript:alert\('XSS'\);//">$}, "BASE tag - XXX Check rule for base-href");

$H = <<EOF;
<OBJECT TYPE="text/x-scriptlet" DATA="http://ha.ckers.org/scriptlet.html"></OBJECT>
EOF
$R = $D->defang($H);
like($R, qr{^<!--${DefangString}OBJECT defang_TYPE="text/x-scriptlet" defang_DATA="http://ha.ckers.org/scriptlet.html"--><!--/${DefangString}OBJECT-->$}, "OBJECT tag");

$H = <<EOF;
<applet code=A21 width=256 height=256 archive="toir.jar"></applet>
EOF
$R = $D->defang($H);
like($R, qr{^<!--${DefangString}applet defang_code=A21 width=256 height=256 defang_archive="toir.jar"--><!--/${DefangString}applet-->$}, "Applet tag");

$H = <<EOF;
<OBJECT classid=clsid:ae24fdae-03c6-11d1-8b76-0080c744f389><param name=url value=javascript:alert('XSS')></OBJECT>
EOF
$R = $D->defang($H);
like($R, qr{^<!--${DefangString}OBJECT defang_classid=clsid:ae24fdae-03c6-11d1-8b76-0080c744f389--><!--${DefangString}param name=url defang_value=javascript:alert\(&apos;XSS&apos;\)--><!--/${DefangString}OBJECT-->$}, "Using an OBJECT tag you can embed XSS directly");

$H = <<EOF;
<EMBED SRC="http://ha.ckers.org/xss.swf" AllowScriptAccess="always"></EMBED>
EOF
$R = $D->defang($H);
like($R, qr{^<!--${DefangString}EMBED defang_SRC="http://ha.ckers.org/xss.swf" defang_AllowScriptAccess="always"--><!--/${DefangString}EMBED-->$}, "Using an EMBED tag you can embed a Flash movie that contains XSS");

$H = <<EOF;
<EMBED SRC="data:image/svg+xml;base64,PHN2ZyB4bWxuczpzdmc9Imh0dH A6Ly93d3cudzMub3JnLzIwMDAvc3ZnIiB4bWxucz0iaHR0cDovL3d3dy53My5vcmcv MjAwMC9zdmciIHhtbG5zOnhsaW5rPSJodHRwOi8vd3d3LnczLm9yZy8xOTk5L3hs aW5rIiB2ZXJzaW9uPSIxLjAiIHg9IjAiIHk9IjAiIHdpZHRoPSIxOTQiIGhlaWdodD0iMjAw IiBpZD0ieHNzIj48c2NyaXB0IHR5cGU9InRleHQvZWNtYXNjcmlwdCI+YWxlcnQoIlh TUyIpOzwvc2NyaXB0Pjwvc3ZnPg==" type="image/svg+xml" AllowScriptAccess="always"></EMBED>
EOF
$R = $D->defang($H);
like($R, qr{^<!--${DefangString}EMBED defang_SRC="data:image/svg\+xml;base64,PHN2ZyB4bWxuczpzdmc9Imh0dH A6Ly93d3cudzMub3JnLzIwMDAvc3ZnIiB4bWxucz0iaHR0cDovL3d3dy53My5vcmcv MjAwMC9zdmciIHhtbG5zOnhsaW5rPSJodHRwOi8vd3d3LnczLm9yZy8xOTk5L3hs aW5rIiB2ZXJzaW9uPSIxLjAiIHg9IjAiIHk9IjAiIHdpZHRoPSIxOTQiIGhlaWdodD0iMjAw IiBpZD0ieHNzIj48c2NyaXB0IHR5cGU9InRleHQvZWNtYXNjcmlwdCI\+YWxlcnQoIlh TUyIpOzwvc2NyaXB0Pjwvc3ZnPg==" defang_type="image/svg\+xml" defang_AllowScriptAccess="always"--><!--/${DefangString}EMBED-->$}, "You can EMBED SVG which can contain your XSS vector");

$H = <<EOF;
EOF
$R = $D->defang($H);
like($R, qr{^$}, "Using ActionScript inside flash can obfuscate your XSS vector - XXX Flash should be caught elsewhere were we defang OBJECT and EMBED tags. Leaving this test here for the sake of comprehensiveness");

$H = <<EOF;
<HTML xmlns:xss>
  <?import namespace="xss" implementation="http://ha.ckers.org/xss.htc">
    <xss:xss>XSS</xss:xss>
    </HTML>
EOF
$R = $D->defang($H);
like($R, qr{^<HTML defang_xmlns:xss>\s*<!--\?import namespace="xss" implementation="http://ha.ckers.org/xss.htc"-->\s*<!--${DefangString}xss:xss-->XSS<!--/${DefangString}xss:xss-->\s*</HTML>$}, "XML namespace");

$H = <<EOF;
<style/onload=&#x0a;alert(&quot;foo")>
EOF
$R = $D->defang($H);
like($R, qr{^<style/defang_onload=&#x0a;alert\(&quot;foo&quot;\)><!--${CommentStartText}${CommentEndText}--></style>$}, "style with event handler");

$CommentStartText = '/\*SC\*/';
$CommentEndText = '/\*EC\*/';

$H = <<EOF;
<XML ID=I><X><C><![CDATA[<IMG SRC="javas]]><![CDATA[cript:alert('XSS');">]]>
</C></X></xml><SPAN DATASRC=#I DATAFLD=C DATAFORMATAS=HTML></SPAN>
EOF
$R = $D->defang($H);
like($R, qr{^<!--${DefangString}XML ID=I--><!--${DefangString}X--><!--${DefangString}C--><!--${CommentStartText}\[CDATA\[<IMG SRC="javas\]\]${CommentEndText}--><!--${CommentStartText}\[CDATA\[cript:alert\('XSS'\);">\]\]${CommentEndText}-->\s<!--/${DefangString}C--><!--/${DefangString}X--><!--/${DefangString}xml--><SPAN defang_DATASRC=#I defang_DATAFLD=C defang_DATAFORMATAS=HTML></SPAN>$}, "XML data island with CDATA obfuscation");

$H = <<EOF;
<XML ID="xss"><I><B>&lt;IMG SRC="javas<!-- -->cript:alert('XSS')"&gt;</B></I></XML>
<SPAN DATASRC="#xss" DATAFLD="B" DATAFORMATAS="HTML"></SPAN>
EOF
$R = $D->defang($H);
like($R, qr{^<!--${DefangString}XML ID="xss"--><I><B>&lt;IMG SRC="javas<!--${CommentStartText} ${CommentEndText}-->cript:alert\('XSS'\)"&gt;</B></I><!--/${DefangString}XML-->
<SPAN defang_DATASRC="#xss" defang_DATAFLD="B" defang_DATAFORMATAS="HTML"></SPAN>$}, "XML data island with comment obfuscation");

$H = <<EOF;
<XML SRC="xsstest.xml" ID=I></XML>
<SPAN DATASRC=#I DATAFLD=C DATAFORMATAS=HTML></SPAN>
EOF
$R = $D->defang($H);
like($R, qr{^<!--${DefangString}XML defang_SRC="xsstest.xml" ID=I--><!--/${DefangString}XML-->\s<SPAN defang_DATASRC=#I defang_DATAFLD=C defang_DATAFORMATAS=HTML></SPAN>$}, "Locally hosted XML with embedded JavaScript that is generated using an XML data island");

$H = <<EOF;
<HTML><BODY>
<?xml:namespace prefix="t" ns="urn:schemas-microsoft-com:time">
<?import namespace="t" implementation="#default#time2">
<t:set attributeName="innerHTML" to="XSS&lt;SCRIPT DEFER&gt;alert(&quot;XSS&quot;)&lt;/SCRIPT&gt;">
</BODY></HTML>
EOF
$R = $D->defang($H);
like($R, qr{^<HTML><BODY>\s<!--\?xml:namespace prefix="t" ns="urn:schemas-microsoft-com:time"-->\s<!--\?import namespace="t" implementation="#default#time2"-->\s<!--${DefangString}t:set defang_attributeName="innerHTML" defang_to="XSS&lt;SCRIPT DEFER&gt;alert\(&quot;XSS&quot;\)&lt;/SCRIPT&gt;"-->\s</BODY></HTML>$}, "HTML+TIME in XML");

$CommentStartText = '';
$CommentEndText = '';
$H = <<EOF;
<SCRIPT SRC="http://ha.ckers.org/xss.jpg"></SCRIPT>
EOF
$R = $D->defang($H);
like($R, qr{^<!--${DefangString}SCRIPT SRC="http://ha.ckers.org/xss.jpg"--><!--${CommentStartText}  ${CommentEndText}--><!--/${DefangString}SCRIPT-->$}, "Rename your JavaScript file to an image as an XSS vector");

$CommentStartText = '/\*SC\*/';
$CommentEndText = '/\*EC\*/';
$H = <<EOF;
<!--#exec cmd="/bin/echo '<SCR'"--><!--#exec cmd="/bin/echo 'IPT SRC=http://ha.ckers.org/xss.js></SCRIPT>'"-->
EOF
$R = $D->defang($H);
like($R, qr{^<!--${CommentStartText}#exec cmd="/bin/echo '<SCR'"${CommentEndText}--><!--${CommentStartText}#exec cmd="/bin/echo 'IPT SRC=http://ha.ckers.org/xss.js></SCRIPT>'"${CommentEndText}-->$}, "SSI (Server Side Includes) - XXX Server side");

$CommentStartText = '';
$CommentEndText = '';
$H = <<EOF;
<? echo('<SCR)';
echo('IPT>alert("XSS")</SCRIPT>'); ?>
EOF
$R = $D->defang($H);
like($R, qr{^<!--\? echo\('<SCR\)';\secho\('IPT-->alert\("XSS"\)<!--/${DefangString}SCRIPT-->'\); \?>$}, "PHP - XXX Server side");

$H = <<EOF;
<IMG SRC="http://www.thesiteyouareon.com/somecommand.php?somevariables=maliciouscode">
EOF
$R = $D->defang($H);
like($R, qr{^<IMG SRC="http://www.thesiteyouareon.com/somecommand.php\?somevariables=maliciouscode">$}, "IMG Embedded commands - XXX Defang all images? And probably links as well?");

$H = <<EOF;
EOF
$R = $D->defang($H);
like($R, qr{^$}, "IMG Embedded commands part II - XXX This would probably mean we cannot allow any sort of external links, and have to defang all images ");

$H = <<EOF;
<META HTTP-EQUIV="Set-Cookie" Content="USERID=&lt;SCRIPT&gt;alert('XSS')&lt;/SCRIPT&gt;">
EOF
$R = $D->defang($H);
like($R, qr{^<META defang_HTTP-EQUIV="Set-Cookie" defang_Content="USERID=&lt;SCRIPT&gt;alert\('XSS'\)&lt;/SCRIPT&gt;">$}, "Cookie manipulation");

#	$H = <<EOF;
#	<HEAD><META HTTP-EQUIV="CONTENT-TYPE" CONTENT="text/html; charset=UTF-7"> </HEAD>+ADw-SCRIPT+AD4-alert('XSS');+ADw-/SCRIPT+AD4-
#	EOF
#	$R = $D->defang($H);
#	like($R, qr{^<HEAD><META HTTP-EQUIV="CONTENT-TYPE" defang_CONTENT="text/html; charset=UTF-7"> </HEAD><!--${DefangString}SCRIPT--><!--${CommentStartText} alert\('XSS'\); ${CommentEndText}--><!--/${DefangString}SCRIPT-->$}, "UTF-7 encoding specified in <meta> tag");

#	$H = <<EOF;
#	<HEAD></HEAD>+ADw-SCRIPT+AD4-alert('XSS');+ADw-/SCRIPT+AD4-
#	EOF
#	$R = $D->defang($H, { header_charset => "UTF-7" });
#	like($R, qr{^<HEAD></HEAD><!--${DefangString}SCRIPT--><!--${CommentStartText} alert\('XSS'\); ${CommentEndText}--><!--/${DefangString}SCRIPT-->$}, "UTF-7 encoding specified in HTTP header");

#	$H = <<EOF;
#	<HEAD></HEAD>+ADw-SCRIPT+AD4-alert('XSS');+ADw-/SCRIPT+AD4-
#	EOF
#	$R = $D->defang($H, { fallback_charset => "UTF-7" });
#	like($R, qr{^<HEAD></HEAD><!--${DefangString}SCRIPT--><!--${CommentStartText} alert\('XSS'\); ${CommentEndText}--><!--/${DefangString}SCRIPT-->$}, "UTF-7 encoding specified as fallback charset");

# Browsers appear to give priority to the headers rather than the <meta> tag, so we need to make sure our script works the same way
#	$H = <<EOF;
#	<HEAD><META HTTP-EQUIV="CONTENT-TYPE" CONTENT="text/html; charset=ASCII"> </HEAD>+ADw-SCRIPT+AD4-alert('XSS');+ADw-/SCRIPT+AD4-
#	EOF
#	$R = $D->defang($H, { header_charset => "UTF-7" });
#	like($R, qr{^<HEAD><META HTTP-EQUIV="CONTENT-TYPE" defang_CONTENT="text/html; charset=ASCII"> </HEAD><!--${DefangString}SCRIPT--><!--${CommentStartText} alert\('XSS'\); ${CommentEndText}--><!--/${DefangString}SCRIPT-->$}, "UTF-7 encoding overridden by headers");

#	$H = <<EOF;
#	<HEAD></HEAD>+ADw-SCRIPT+AD4-alert('XSS');+ADw-/SCRIPT+AD4-
#	EOF
#	$R = $D->defang($H);
#	like($R, qr{^<HEAD></HEAD>\+ADw-SCRIPT\+AD4-alert\('XSS'\);\+ADw-/SCRIPT\+AD4-$}, "Skip UTF-7 encoded data when no header, meta or fallback charset");

$H = <<EOF;
<SCRIPT a=">" SRC="http://ha.ckers.org/xss.js"></SCRIPT>
EOF
$R = $D->defang($H);
like($R, qr{^<!--${DefangString}SCRIPT a="-->" SRC="http://ha.ckers.org/xss.js"><!--||--/\*SC\*/  /\*EC\*/--||--><!--/${DefangString}SCRIPT-->$}, "XSS using HTML quote encapsulation");

$H = <<EOF;
<SCRIPT =">" SRC="http://ha.ckers.org/xss.js"></SCRIPT>
EOF
$R = $D->defang($H);
like($R, qr{^<!--${DefangString}SCRIPT ="-->" SRC="http://ha.ckers.org/xss.js"><!--||--/\*SC\*/  /\*EC\*/--||--><!--/${DefangString}SCRIPT-->$}, "For performing XSS on sites that allow \"<SCRIPT>\" but don't allow \"<script src...\" by way of a regex filter");

$H = <<EOF;
<SCRIPT a=">" '' SRC="http://ha.ckers.org/xss.js"></SCRIPT>
EOF
$R = $D->defang($H);
like($R, qr{^<!--${DefangString}SCRIPT a="-->" '' SRC="http://ha.ckers.org/xss.js"><!--||--/\*SC\*/  /\*EC\*/--||--><!--/${DefangString}SCRIPT-->$}, "Another XSS to evade the same filter");

$H = <<EOF;
<SCRIPT "a='>'" SRC="http://ha.ckers.org/xss.js"></SCRIPT>
EOF
$R = $D->defang($H);
like($R, qr{^<!--${DefangString}SCRIPT "a='-->'" SRC="http://ha.ckers.org/xss.js"><!--||--/\*SC\*/  /\*EC\*/--||--><!--/${DefangString}SCRIPT-->$}, "Yet another XSS to evade the same filter");

$H = <<EOF;
<SCRIPT a=`>` SRC="http://ha.ckers.org/xss.js"></SCRIPT>
EOF
$R = $D->defang($H);
like($R, qr{^<!--${DefangString}SCRIPT a=`-->` SRC="http://ha.ckers.org/xss.js"><!--||--/\*SC\*/  /\*EC\*/--||--><!--/${DefangString}SCRIPT-->$}, "And one last XSS attack to evade");

$H = <<EOF;
<SCRIPT a=">'>" SRC="http://ha.ckers.org/xss.js"></SCRIPT>
EOF
$R = $D->defang($H);
like($R, qr{^<!--${DefangString}SCRIPT a="-->'>" SRC="http://ha.ckers.org/xss.js"><!--||--/\*SC\*/  /\*EC\*/--||--><!--/${DefangString}SCRIPT-->$}, "Regex won't catch a matching pair of quotes");

$H = <<EOF;
<SCRIPT>document.write("<SCRI");</SCRIPT>PT SRC="http://ha.ckers.org/xss.js"></SCRIPT>
EOF
$R = $D->defang($H);
like($R, qr{^<!--${DefangString}SCRIPT--><!--${CommentStartText} document.write\("<SCRI"\); ${CommentEndText}--><!--/${DefangString}SCRIPT-->PT SRC="http://ha.ckers.org/xss.js"><!--/${DefangString}SCRIPT-->$}, "Scripting within a script");

$H = <<EOF;
<SCRIPT>a--; document.write("-->"); <img onload=alert("xss")></script>
EOF
$R = $D->defang($H);
like($R, qr{^<!--${DefangString}SCRIPT--><!-- a; document\.write\(""\); <img onload=alert\("xss"\)> --><!--/${DefangString}script-->$}, "script contents with -- and --> end comment in it");

$H = <<EOF;
<a href="<">
EOF
$R = $D->defang($H);
like($R, qr{^<a defang_href="&lt;">$}, '<a href="<">');

$H = <<EOF;
<a href="%3C">
EOF
$R = $D->defang($H);
like($R, qr{^<a defang_href="%3C">$}, '<a href="%3C">');

$H = <<EOF;
<a href="&#60">
EOF
$R = $D->defang($H);
like($R, qr{^<a defang_href="&lt;">$}, '<a href="&#60">');

$H = <<EOF;
<a href="&#060">
EOF
$R = $D->defang($H);
like($R, qr{^<a defang_href="&lt;">$}, '<a href="&#060">');

$H = <<EOF;
<a href="&#0060">
EOF
$R = $D->defang($H);
like($R, qr{^<a defang_href="&lt;">$}, '<a href="&#0060">');

$H = <<EOF;
<a href="&#00060">
EOF
$R = $D->defang($H);
like($R, qr{^<a defang_href="&lt;">$}, '<a href="&#00060">');

$H = <<EOF;
<a href="&#000060">
EOF
$R = $D->defang($H);
like($R, qr{^<a defang_href="&lt;">$}, '<a href="&#000060">');

$H = <<EOF;
<a href="&#0000060">
EOF
$R = $D->defang($H);
like($R, qr{^<a defang_href="&lt;">$}, '<a href="&#0000060">');

$H = <<EOF;
<a href="&#60;">
EOF
$R = $D->defang($H);
like($R, qr{^<a defang_href="&lt;">$}, '<a href="&#60;">');

$H = <<EOF;
<a href="&#060;">
EOF
$R = $D->defang($H);
like($R, qr{^<a defang_href="&lt;">$}, '<a href="&#060;">');

$H = <<EOF;
<a href="&#0060;">
EOF
$R = $D->defang($H);
like($R, qr{^<a defang_href="&lt;">$}, '<a href="&#0060;">');

$H = <<EOF;
<a href="&#00060;">
EOF
$R = $D->defang($H);
like($R, qr{^<a defang_href="&lt;">$}, '<a href="&#00060;">');

$H = <<EOF;
<a href="&#000060;">
EOF
$R = $D->defang($H);
like($R, qr{^<a defang_href="&lt;">$}, '<a href="&#000060;">');

$H = <<EOF;
<a href="&#0000060;">
EOF
$R = $D->defang($H);
like($R, qr{^<a defang_href="&lt;">$}, '<a href="&#0000060;">');

$H = <<EOF;
<a href="&#x3c">
EOF
$R = $D->defang($H);
like($R, qr{^<a defang_href="&lt;">$}, '<a href="&#x3c">');

$H = <<EOF;
<a href="&#x03c">
EOF
$R = $D->defang($H);
like($R, qr{^<a defang_href="&lt;">$}, '<a href="&#x03c">');

$H = <<EOF;
<a href="&#x003c">
EOF
$R = $D->defang($H);
like($R, qr{^<a defang_href="&lt;">$}, '<a href="&#x003c">');

$H = <<EOF;
<a href="&#x0003c">
EOF
$R = $D->defang($H);
like($R, qr{^<a defang_href="&lt;">$}, '<a href="&#x0003c">');

$H = <<EOF;
<a href="&#x00003c">
EOF
$R = $D->defang($H);
like($R, qr{^<a defang_href="&lt;">$}, '<a href="&#x00003c">');

$H = <<EOF;
<a href="&#x000003c">
EOF
$R = $D->defang($H);
like($R, qr{^<a defang_href="&lt;">$}, '<a href="&#x000003c">');

$H = <<EOF;
<a href="&#x3c;">
EOF
$R = $D->defang($H);
like($R, qr{^<a defang_href="&lt;">$}, '<a href="&#x3c;">');

$H = <<EOF;
<a href="&#x03c;">
EOF
$R = $D->defang($H);
like($R, qr{^<a defang_href="&lt;">$}, '<a href="&#x03c;">');

$H = <<EOF;
<a href="&#x003c;">
EOF
$R = $D->defang($H);
like($R, qr{^<a defang_href="&lt;">$}, '<a href="&#x003c;">');

$H = <<EOF;
<a href="&#x0003c;">
EOF
$R = $D->defang($H);
like($R, qr{^<a defang_href="&lt;">$}, '<a href="&#x0003c;">');

$H = <<EOF;
<a href="&#x00003c;">
EOF
$R = $D->defang($H);
like($R, qr{^<a defang_href="&lt;">$}, '<a href="&#x00003c;">');

$H = <<EOF;
<a href="&#x000003c;">
EOF
$R = $D->defang($H);
like($R, qr{^<a defang_href="&lt;">$}, '<a href="&#x000003c;">');

$H = <<EOF;
<a href="&#X3c">
EOF
$R = $D->defang($H);
like($R, qr{^<a defang_href="&lt;">$}, '<a href="&#X3c">');

$H = <<EOF;
<a href="&#X03c">
EOF
$R = $D->defang($H);
like($R, qr{^<a defang_href="&lt;">$}, '<a href="&#X03c">');

$H = <<EOF;
<a href="&#X003c">
EOF
$R = $D->defang($H);
like($R, qr{^<a defang_href="&lt;">$}, '<a href="&#X003c">');

$H = <<EOF;
<a href="&#X0003c">
EOF
$R = $D->defang($H);
like($R, qr{^<a defang_href="&lt;">$}, '<a href="&#X0003c">');

$H = <<EOF;
<a href="&#X00003c">
EOF
$R = $D->defang($H);
like($R, qr{^<a defang_href="&lt;">$}, '<a href="&#X00003c">');

$H = <<EOF;
<a href="&#X000003c">
EOF
$R = $D->defang($H);
like($R, qr{^<a defang_href="&lt;">$}, '<a href="&#X000003c">');

$H = <<EOF;
<a href="&#X3c;">
EOF
$R = $D->defang($H);
like($R, qr{^<a defang_href="&lt;">$}, '<a href="&#X3c;">');

$H = <<EOF;
<a href="&#X03c;">
EOF
$R = $D->defang($H);
like($R, qr{^<a defang_href="&lt;">$}, '<a href="&#X03c;">');

$H = <<EOF;
<a href="&#X003c;">
EOF
$R = $D->defang($H);
like($R, qr{^<a defang_href="&lt;">$}, '<a href="&#X003c;">');

$H = <<EOF;
<a href="&#X0003c;">
EOF
$R = $D->defang($H);
like($R, qr{^<a defang_href="&lt;">$}, '<a href="&#X0003c;">');

$H = <<EOF;
<a href="&#X00003c;">
EOF
$R = $D->defang($H);
like($R, qr{^<a defang_href="&lt;">$}, '<a href="&#X00003c;">');

$H = <<EOF;
<a href="&#X000003c;">
EOF
$R = $D->defang($H);
like($R, qr{^<a defang_href="&lt;">$}, '<a href="&#X000003c;">');

$H = <<EOF;
<a href="&#x3C">
EOF
$R = $D->defang($H);
like($R, qr{^<a defang_href="&lt;">$}, '<a href="&#x3C">');

$H = <<EOF;
<a href="&#x03C">
EOF
$R = $D->defang($H);
like($R, qr{^<a defang_href="&lt;">$}, '<a href="&#x03C">');

$H = <<EOF;
<a href="&#x003C">
EOF
$R = $D->defang($H);
like($R, qr{^<a defang_href="&lt;">$}, '<a href="&#x003C">');

$H = <<EOF;
<a href="&#x0003C">
EOF
$R = $D->defang($H);
like($R, qr{^<a defang_href="&lt;">$}, '<a href="&#x0003C">');

$H = <<EOF;
<a href="&#x00003C">
EOF
$R = $D->defang($H);
like($R, qr{^<a defang_href="&lt;">$}, '<a href="&#x00003C">');

$H = <<EOF;
<a href="&#x000003C">
EOF
$R = $D->defang($H);
like($R, qr{^<a defang_href="&lt;">$}, '<a href="&#x000003C">');

$H = <<EOF;
<a href="&#x3C;">
EOF
$R = $D->defang($H);
like($R, qr{^<a defang_href="&lt;">$}, '<a href="&#x3C;">');

$H = <<EOF;
<a href="&#x03C;">
EOF
$R = $D->defang($H);
like($R, qr{^<a defang_href="&lt;">$}, '<a href="&#x03C;">');

$H = <<EOF;
<a href="&#x003C;">
EOF
$R = $D->defang($H);
like($R, qr{^<a defang_href="&lt;">$}, '<a href="&#x003C;">');

$H = <<EOF;
<a href="&#x0003C;">
EOF
$R = $D->defang($H);
like($R, qr{^<a defang_href="&lt;">$}, '<a href="&#x0003C;">');

$H = <<EOF;
<a href="&#x00003C;">
EOF
$R = $D->defang($H);
like($R, qr{^<a defang_href="&lt;">$}, '<a href="&#x00003C;">');

$H = <<EOF;
<a href="&#x000003C;">
EOF
$R = $D->defang($H);
like($R, qr{^<a defang_href="&lt;">$}, '<a href="&#x000003C;">');

$H = <<EOF;
<a href="&#X3C">
EOF
$R = $D->defang($H);
like($R, qr{^<a defang_href="&lt;">$}, '<a href="&#X3C">');

$H = <<EOF;
<a href="&#X03C">
EOF
$R = $D->defang($H);
like($R, qr{^<a defang_href="&lt;">$}, '<a href="&#X03C">');

$H = <<EOF;
<a href="&#X003C">
EOF
$R = $D->defang($H);
like($R, qr{^<a defang_href="&lt;">$}, '<a href="&#X003C">');

$H = <<EOF;
<a href="&#X0003C">
EOF
$R = $D->defang($H);
like($R, qr{^<a defang_href="&lt;">$}, '<a href="&#X0003C">');

$H = <<EOF;
<a href="&#X00003C">
EOF
$R = $D->defang($H);
like($R, qr{^<a defang_href="&lt;">$}, '<a href="&#X00003C">');

$H = <<EOF;
<a href="&#X000003C">
EOF
$R = $D->defang($H);
like($R, qr{^<a defang_href="&lt;">$}, '<a href="&#X000003C">');

$H = <<EOF;
<a href="&#X3C;">
EOF
$R = $D->defang($H);
like($R, qr{^<a defang_href="&lt;">$}, '<a href="&#X3C;">');

$H = <<EOF;
<a href="&#X03C;">
EOF
$R = $D->defang($H);
like($R, qr{^<a defang_href="&lt;">$}, '<a href="&#X03C;">');

$H = <<EOF;
<a href="&#X003C;">
EOF
$R = $D->defang($H);
like($R, qr{^<a defang_href="&lt;">$}, '<a href="&#X003C;">');

$H = <<EOF;
<a href="&#X0003C;">
EOF
$R = $D->defang($H);
like($R, qr{^<a defang_href="&lt;">$}, '<a href="&#X0003C;">');

$H = <<EOF;
<a href="&#X00003C;">
EOF
$R = $D->defang($H);
like($R, qr{^<a defang_href="&lt;">$}, '<a href="&#X00003C;">');

$H = <<EOF;
<a href="&#X000003C;">
EOF
$R = $D->defang($H);
like($R, qr{^<a defang_href="&lt;">$}, '<a href="&#X000003C;">');

$H = <<EOF;
<a href="\x3c">
EOF
$R = $D->defang($H);
like($R, qr{^<a defang_href="&lt;">$}, '<a href="\x3c">');

$H = <<EOF;
<a href="\x3C">
EOF
$R = $D->defang($H);
like($R, qr{^<a defang_href="&lt;">$}, '<a href="\x3C">');

$H = <<EOF;
<img border="&{bbb};asfd&{s};&{ss}">
EOF
$R = $D->defang($H);
like($R, qr{^<img defang_border="&amp;{bbb};asfd&amp;{s};&amp;{ss}">$}, "Strip Javascript entities from known tag with attributes");

$H = <<EOF;
<br size="&{bbb};asfd&{s};&{ss}">
EOF
$R = $D->defang($H);
like($R, qr{^<br defang_size="&amp;{bbb};asfd&amp;{s};&amp;{ss}">$}, "Strip Javascript entities from whitelisted tag");

