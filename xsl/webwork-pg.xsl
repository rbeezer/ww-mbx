<?xml version="1.0" encoding="UTF-8" ?>

<!-- ********************************************************************* -->
<!-- Copyright 2015                                                        -->
<!-- Robert A. Beezer, Michael Gage, Geoff Goehle, Alex Jordan             -->
<!--                                                                       -->
<!-- This file is part of MathBook XML.                                    -->
<!--                                                                       -->
<!-- MathBook XML is free software: you can redistribute it and/or modify  -->
<!-- it under the terms of the GNU General Public License as published by  -->
<!-- the Free Software Foundation, either version 2 or version 3 of the    -->
<!-- License (at your option).                                             -->
<!--                                                                       -->
<!-- MathBook XML is distributed in the hope that it will be useful,       -->
<!-- but WITHOUT ANY WARRANTY; without even the implied warranty of        -->
<!-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the         -->
<!-- GNU General Public License for more details.                          -->
<!--                                                                       -->
<!-- You should have received a copy of the GNU General Public License     -->
<!-- along with MathBook XML.  If not, see <http://www.gnu.org/licenses/>. -->
<!-- ********************************************************************* -->

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
    xmlns:xml="http://www.w3.org/XML/1998/namespace"
>

<!-- path assumes we place  webwork-pg.xsl in mathbook "user" directory -->
<!-- <xsl:import href="../xsl/mathbook-common.xsl" /> -->

<!-- Intend output to be a PGML problem -->
<xsl:output method="text" />


<!-- Parameters to pass via xsltproc "stringparam" on command-line            -->
<!-- Or make a thin customization layer and use 'select' to provide overrides -->
<!--  -->
<!-- Enable answer format syntax help links                       -->
<!-- Each variable has a "category", like "integer" or "formula". -->
<!-- When an answer blank is expecting a variable, use category   -->
<!-- to provide AnswerFormatHelp link.                            -->
<xsl:param name="pg.answer.format.help" select="'yes'" />


<!-- Removing whitespace: http://stackoverflow.com/questions/1468984/xslt-remove-whitespace-from-template -->
<xsl:strip-space elements="li" />


<!-- ################## -->
<!-- Top-Down Structure -->
<!-- ################## -->

<!-- Basic outline of a simple problem -->
<xsl:template match="webwork">
    <xsl:call-template   name="begin-problem" />
    <xsl:call-template   name="macros" />
    <xsl:call-template   name="header" />
    <xsl:apply-templates select="setup" />
    <xsl:apply-templates select="statement" />
    <xsl:apply-templates select="solution" />
    <xsl:call-template   name="end-problem" />
</xsl:template>

<!-- Basic outline of a "scaffold" problem -->
<xsl:template match="webwork[@type='scaffold']">
    <xsl:call-template   name="begin-problem" />
    <xsl:call-template   name="macros" />
    <xsl:call-template   name="header" />
    <xsl:apply-templates select="setup" />
    <xsl:call-template name="begin-block">
        <xsl:with-param name="title">Scaffold</xsl:with-param>
    </xsl:call-template>
    <xsl:text>Scaffold::Begin();&#xa;</xsl:text>
    <xsl:apply-templates select="platform" />
    <xsl:text>&#xa;</xsl:text>
    <xsl:text>Scaffold::End();&#xa;</xsl:text>
    <xsl:call-template   name="end-problem" />
</xsl:template>

<xsl:template match="setup">
    <xsl:call-template name="begin-block">
        <xsl:with-param name="title">PG Setup</xsl:with-param>
    </xsl:call-template>
    <!-- TODO: ignore var for now -->
    <!-- pg-code verbatim, but trim indentation -->
    <xsl:call-template name="sanitize-code">
        <xsl:with-param name="raw-code" select="pg-code" />
    </xsl:call-template>
</xsl:template>

<!-- A platform is part of a scaffold -->
<xsl:template match="platform">
    <xsl:call-template name="begin-block">
        <xsl:with-param name="title">Section</xsl:with-param>
    </xsl:call-template>
    <xsl:text>Section::Begin("</xsl:text>
    <xsl:apply-templates select="title" />
    <xsl:text>");&#xa;</xsl:text>
    <xsl:apply-templates select="statement" />
    <xsl:apply-templates select="solution" />
    <xsl:text>&#xa;</xsl:text>
    <xsl:text>Section::End();&#xa;</xsl:text>
</xsl:template>


<!-- default template, for complete presentation -->
<!-- TODO: fix match pattern to cover scaffolded problems once name firms up -->
<xsl:template match="webwork//statement">
    <xsl:call-template name="begin-block">
        <xsl:with-param name="title">Body</xsl:with-param>
    </xsl:call-template>
    <xsl:text>BEGIN_PGML&#xa;</xsl:text>
    <xsl:apply-templates />
    <!-- unless we guarantee line feed, a break is needed -->
    <xsl:text>&#xa;</xsl:text>
    <xsl:text>END_PGML&#xa;</xsl:text>
</xsl:template>

<!-- default template, for solution -->
<!-- TODO: fix match pattern to cover scaffolded problems once name firms up -->
<xsl:template match="webwork//solution">
    <xsl:call-template name="begin-block">
        <xsl:with-param name="title">Solution</xsl:with-param>
    </xsl:call-template>
    <xsl:text>BEGIN_PGML_SOLUTION&#xa;</xsl:text>
    <xsl:apply-templates />
    <!-- unless we guarantee line feed, a break is needed -->
    <xsl:text>&#xa;</xsl:text>
    <xsl:text>END_PGML_SOLUTION&#xa;</xsl:text>
</xsl:template>

<!-- In PGML, paragraph breaks are just blank lines -->
<!-- End as normal with a line feed, then           -->
<!-- issue a blank line to signify the break        -->
<!-- If p is inside a list, special handling        -->
<xsl:template match="webwork//p">
    <xsl:if test="preceding-sibling::p">
        <xsl:call-template name="space">
            <xsl:with-param name="blocksize" select="4"/>
            <xsl:with-param name="repetitions" select="count(ancestor::ul) + count(ancestor::ol)"/>
        </xsl:call-template>
    </xsl:if>
    <xsl:apply-templates />
    <xsl:if test="parent::li and not(../following-sibling::li) and not(../following::*[1][self::li])">
        <xsl:call-template name="space">
            <xsl:with-param name="blocksize" select="3"/>
            <xsl:with-param name="repetitions" select="1"/>
        </xsl:call-template>
    </xsl:if>
    <xsl:text>&#xa;</xsl:text>
    <xsl:text>&#xa;</xsl:text>
</xsl:template>

<!-- Implement PGML unordered lists                 -->
<xsl:template match="webwork//ul|webwork//ol">
    <xsl:apply-templates />
    <xsl:text>&#xa;</xsl:text>
</xsl:template>

<xsl:template match="ul/li[ancestor::webwork]">
    <xsl:call-template name="space">
        <xsl:with-param name="blocksize" select="4"/>
        <xsl:with-param name="repetitions" select="count(ancestor::ul) + count(ancestor::ol) - 1"/>
    </xsl:call-template>
    <xsl:choose>
        <xsl:when test="../@label='disc'">*</xsl:when>
        <xsl:when test="../@label='circle'">o</xsl:when>
        <xsl:when test="../@label='square'">+</xsl:when>
        <xsl:otherwise>-</xsl:otherwise>
    </xsl:choose>
    <xsl:text> </xsl:text>
    <xsl:apply-templates />
    <xsl:if test="not(child::p) and not(following-sibling::li) and not(following::*[1][self::li])">
        <xsl:call-template name="space">
            <xsl:with-param name="blocksize" select="3"/>
            <xsl:with-param name="repetitions" select="1"/>
        </xsl:call-template>
    </xsl:if>
    <xsl:text>&#xa;</xsl:text>
</xsl:template>

<xsl:template match="ol/li[ancestor::webwork]">
    <xsl:call-template name="space">
        <xsl:with-param name="blocksize" select="4"/>
        <xsl:with-param name="repetitions" select="count(ancestor::ul) + count(ancestor::ol) - 1"/>
    </xsl:call-template>
    <xsl:choose>
        <xsl:when test="contains(../@label,'1')">1</xsl:when>
        <xsl:when test="contains(../@label,'a')">a</xsl:when>
        <xsl:when test="contains(../@label,'A')">A</xsl:when>
        <xsl:when test="contains(../@label,'i')">i</xsl:when>
        <xsl:when test="contains(../@label,'I')">I</xsl:when>
        <xsl:otherwise>1</xsl:otherwise>
    </xsl:choose>
    <xsl:text>.  </xsl:text>
    <xsl:apply-templates />
    <xsl:if test="not(child::p) and not(following-sibling::li) and not(following::*[1][self::li])">
        <xsl:call-template name="space">
            <xsl:with-param name="blocksize" select="3"/>
            <xsl:with-param name="repetitions" select="1"/>
        </xsl:call-template>
    </xsl:if>
    <xsl:text>&#xa;</xsl:text>
</xsl:template>


<!-- PGML markup for Perl variable in LaTeX expression -->
<xsl:template match="statement//var|solution//var">
    <xsl:text>[</xsl:text>
    <xsl:value-of select="@name" />
    <xsl:text>]</xsl:text>
</xsl:template>

<!-- PGML answer blank               -->
<!-- Example: [_____]{$ans}          -->
<xsl:template match="statement//answer">
    <xsl:variable name="width">
        <xsl:choose>
            <xsl:when test="@width">
                 <xsl:value-of select="@width"/>
            </xsl:when>
            <xsl:otherwise>
                 <xsl:text>5</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:text>[</xsl:text>
    <xsl:call-template name="underscore">
        <xsl:with-param name="width">
            <xsl:value-of select="$width"/>
        </xsl:with-param>
    </xsl:call-template>
    <xsl:text>]{</xsl:text>
        <xsl:choose>
            <xsl:when test="@evaluator">
                <xsl:value-of select="@evaluator" />
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="@var" />
            </xsl:otherwise>
        </xsl:choose>
    <xsl:text>}</xsl:text>
    <xsl:if test="$pg.answer.format.help = 'yes'">
        <xsl:variable name="category">
            <xsl:choose>
                <xsl:when test="@category">
                    <xsl:value-of select="@category"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:variable name="varname" select="@var" />
                    <xsl:variable name="problem" select="ancestor::webwork" />
                    <xsl:value-of select="$problem/setup/var[@name=$varname]/@category" />
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="format">
            <xsl:call-template name="category-to-format">
                <xsl:with-param name="category" select="$category"/>
            </xsl:call-template>
        </xsl:variable>
        <xsl:if test="not($format='none')">
            <xsl:text> [@ AnswerFormatHelp("</xsl:text>
                <xsl:value-of select="$format"/>
            <xsl:text>") @]*</xsl:text>
        </xsl:if>
    </xsl:if>
</xsl:template>

<!-- PGML inline math uses its own delimiters  -->
<!-- NB: we allow the "var" element as a child -->
<xsl:template match= "webwork//m">
    <xsl:text>[`</xsl:text>
    <xsl:apply-templates select="text()|var" />
    <xsl:text>`]</xsl:text>
</xsl:template>

<xsl:template match="webwork//me">
    <xsl:text>&#xa;&#xa;&gt;&gt; [``</xsl:text>
    <xsl:apply-templates select="text()|var" />
    <xsl:text>``] &lt;&lt;&#xa;&#xa;</xsl:text>
</xsl:template>


<!-- re-activate, since MBX kills all titles -->
<xsl:template match="webwork//title">
    <xsl:apply-templates />
</xsl:template>


<!-- Unimplemented, currently killed -->
<xsl:template match="webwork//hint" />


<!-- ####################### -->
<!-- Static, Named Templates -->
<!-- ####################### -->

<xsl:template name="begin-problem">
    <xsl:text>DOCUMENT();&#xa;</xsl:text>
</xsl:template>

<xsl:template name="header">
    <xsl:call-template name="begin-block">
        <xsl:with-param name="title">Header</xsl:with-param>
    </xsl:call-template>
    <xsl:text>TEXT(beginproblem());&#xa;</xsl:text>
</xsl:template>

<!-- We kill default processing of "macros" and use       -->
<!-- a named template.  This allows for there to be no    -->
<!-- "macros" element if no additional macros are needed. -->
<!-- Calling context is "webwork" problem-root            -->
<!-- Call from "webwork" context                          -->
<!-- http://stackoverflow.com/questions/9936762/xslt-pass-current-context-in-call-template -->
<xsl:template match="macros" />

<xsl:template name="macros">
    <!-- three standard macro files, order and placement is critical -->
    <xsl:call-template name="begin-block">
        <xsl:with-param name="title">Load Macros</xsl:with-param>
    </xsl:call-template>
    <xsl:text>loadMacros(&#xa;</xsl:text>
    <xsl:text>    "PGstandard.pl",&#xa;</xsl:text>
    <xsl:text>    "MathObjects.pl",&#xa;</xsl:text>
    <xsl:text>    "PGML.pl",&#xa;</xsl:text>
    <!-- look for other macros to use automatically                  -->
    <!-- popup menu multiple choice answers                          -->
    <!-- What conditional???                                         -->
    <xsl:if test="1=1">
        <xsl:text>    "parserPopUp.pl",&#xa;</xsl:text>
    </xsl:if>
    <!-- radio buttons multiple choice answers                       -->
    <!-- What conditional???                                         -->
    <xsl:if test="1=1">
        <xsl:text>    "parserRadioButtons.pl",&#xa;</xsl:text>
    </xsl:if>
    <!-- scaffolded problems -->
    <xsl:if test="@type='scaffold'">
        <xsl:text>    "scaffold.pl",&#xa;</xsl:text>
    </xsl:if>
    <!-- links to syntax help following answer blanks                -->
    <xsl:if test="($pg.answer.format.help = 'yes')">
        <xsl:text>    "AnswerFormatHelp.pl",&#xa;</xsl:text>
    </xsl:if>
    <!-- targeted feedback messages for specific wrong answers       -->
    <xsl:if test="contains(./setup/pg-code,'AnswerHints')">
        <xsl:text>    "answerHints.pl",&#xa;</xsl:text>
    </xsl:if>
    <xsl:apply-templates select="macros/macro" />
    <xsl:text>    "PGcourse.pl",&#xa;</xsl:text>
    <xsl:text>);&#xa;</xsl:text>
</xsl:template>

<!-- NB: final trailing comma controlled by "PGcourse.pl" -->
<xsl:template match="macro">
    <xsl:text>    "</xsl:text>
    <xsl:value-of select="." />
    <xsl:text>",&#xa;</xsl:text>
</xsl:template>

<xsl:template name="end-problem">
    <xsl:call-template name="begin-block">
        <xsl:with-param name="title">End Problem</xsl:with-param>
    </xsl:call-template>
    <xsl:text>ENDDOCUMENT();&#xa;</xsl:text>
</xsl:template>

<xsl:template name="begin-block">
    <xsl:param name="title"/>
    <xsl:text>&#xa;</xsl:text>
    <xsl:text>############################################################&#xa;</xsl:text>
    <xsl:text># </xsl:text>
    <xsl:value-of select="$title"/>
    <xsl:text>&#xa;</xsl:text>
    <xsl:text>############################################################&#xa;</xsl:text>
</xsl:template>

<!-- Since we use XSLT 1.0, this is how we create -->
<!-- "width" underscores for a PGML answer blank  -->
<xsl:template name="underscore">
    <xsl:param name="width" select="5" />
    <xsl:if test="not($width = 0)">
        <xsl:text>_</xsl:text>
        <xsl:call-template name="underscore">
            <xsl:with-param name="width" select="$width - 1" />
        </xsl:call-template>
    </xsl:if>
</xsl:template>

<!-- PGML relies on sequences of space characters for markup -->
<xsl:template name="space">
    <xsl:param name="blocksize" select="4" />
    <xsl:param name="repetitions" select="1" />
    <xsl:param name="width" select="$blocksize * $repetitions" />
    <xsl:if test="not($width = 0)">
        <xsl:text> </xsl:text>
        <xsl:call-template name="space">
            <xsl:with-param name="width" select="$width - 1" />
        </xsl:call-template>
    </xsl:if>
</xsl:template>



<!-- Convert a var's "category" to the right term for AnswerFormatHelp -->
<xsl:template name="category-to-format">
    <xsl:param name="category"/>
    <xsl:choose>
        <xsl:when test="$category='angle'">
            <xsl:text>angles</xsl:text>
        </xsl:when>
        <xsl:when test="$category='decimal'">
            <xsl:text>decimals</xsl:text>
        </xsl:when>
        <xsl:when test="$category='exponent'">
            <xsl:text>exponents</xsl:text>
        </xsl:when>
        <xsl:when test="$category='formula'">
            <xsl:text>formulas</xsl:text>
        </xsl:when>
        <xsl:when test="$category='fraction'">
            <xsl:text>fractions</xsl:text>
        </xsl:when>
        <xsl:when test="$category='inequality'">
            <xsl:text>inequalities</xsl:text>
        </xsl:when>
        <xsl:when test="$category='interval'">
            <xsl:text>intervals</xsl:text>
        </xsl:when>
        <xsl:when test="$category='logarithm'">
            <xsl:text>logarithms</xsl:text>
        </xsl:when>
        <xsl:when test="$category='limit'">
            <xsl:text>limits</xsl:text>
        </xsl:when>
        <xsl:when test="$category='number' or $category='integer'">
            <xsl:text>numbers</xsl:text>
        </xsl:when>
        <xsl:when test="$category='point'">
            <xsl:text>points</xsl:text>
        </xsl:when>
        <xsl:when test="$category='syntax'">
            <xsl:text>syntax</xsl:text>
        </xsl:when>
        <xsl:when test="$category='quantity'">
            <xsl:text>units</xsl:text>
        </xsl:when>
        <xsl:when test="$category='vector'">
            <xsl:text>vectors</xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <xsl:text>none</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>


<!-- ###### -->
<!-- Markup -->
<!-- ###### -->

<!-- http://webwork.maa.org/wiki/Introduction_to_PGML#Basic_Formatting -->

<!-- two spaces at line-end is a newline -->
<xsl:template match="br">
    <xsl:text>  &#xa;</xsl:text>
</xsl:template>


<!-- ######### -->
<!-- Utilities -->
<!-- ######### -->



</xsl:stylesheet>
