#!/usr/bin/perl
use warnings;
use strict;
use XML::Atom::SimpleFeed;

package XML::Atom::SimpleFeed;
use Test::More tests => 7;

is xml_escape( $_ = qq(<\x{FF34}\x{FF25}\x{FF33}\x{FF34} "&' d\xE3t\xE3>) ),
	                qq(&lt;&#65332;&#65317;&#65331;&#65332; &#34;&#38;&#39; d&#227;t&#227;&gt;),
	'XML tag content is properly encoded';

is xml_attr_escape( $_ = qq(<\x{FF34}\x{FF25}\x{FF33}\x{FF34}\n"&'\rd\xE3t\xE3>) ),
	                     qq(&lt;&#65332;&#65317;&#65331;&#65332;&#10;&#34;&#38;&#39;&#13;d&#227;t&#227;&gt;),
	'XML attribute content is properly encoded';

is xml_string( $_ = qq(Test <![CDATA[<CDATA>]]> sections) ),
	                qq(Test &lt;CDATA&gt; sections),
	'CDATA sections are properly flattened';

is xml_tag( 'br' ), '<br/>', 'simple tags are self-closed';
is xml_tag( 'b', 'foo', '<br/>' ), '<b>foo<br/></b>', 'tags with content are properly formed';
is xml_tag( [ 'br', clear => 'left' ] ), '<br clear="left"/>', 'simple tags can have attributes';
is xml_tag( [ 'b', style => 'color: red' ], 'foo', '<br/>' ), '<b style="color: red">foo<br/></b>', 'simple tags can have attributes';
