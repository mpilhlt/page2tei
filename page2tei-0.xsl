<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet
  xmlns="http://www.tei-c.org/ns/1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
  xmlns:tei="http://www.tei-c.org/ns/1.0"
  xmlns:p2017="http://schema.primaresearch.org/PAGE/gts/pagecontent/2017-07-15"
  xmlns:p2019="http://schema.primaresearch.org/PAGE/gts/pagecontent/2019-07-15"
  xmlns:mets="http://www.loc.gov/METS/"
  xmlns:xlink="http://www.w3.org/1999/xlink"
  xmlns:map="http://www.w3.org/2005/xpath-functions/map"
  xmlns:local="local"
  xmlns:xstring = "https://github.com/dariok/XStringUtils"
  exclude-result-prefixes="#all"
  version="3.0">

  <xsl:output indent="no" omit-xml-declaration="no"/>

  <xd:doc>
    <xd:desc>Whether to create `rs type="..."` for person/place/org (default) or `persName` etc. (false())</xd:desc>
  </xd:doc>
  <xsl:param name="rs" select="true()" />

  <xd:doc>
    <xd:desc>Whether to process just the current file or all the xml files in the directory of the current file</xd:desc>
  </xd:doc>
  <xsl:param name="directory_mode" select="false()" />

  <xd:doc>
    <xd:desc>Whether to redirect the output and manage the result document here in xslt</xd:desc>
  </xd:doc>
  <xsl:param name="determine_result_document" select="false()" />
  <xsl:param name="result_doc_path" select="'../../../../03_Bearbeitete_OCR'"/><!-- ../tei-output/complete.xml -->

  <xd:doc scope="stylesheet">
    <xd:desc>
      <xd:p><xd:b>Author:</xd:b> Dario Kampkaspar, dario.kampkaspar@oeaw.ac.at</xd:p>
      <xd:p>Austrian Centre for Digital Humanities http://acdh.oeaw.ac.at</xd:p>
      <xd:p></xd:p>
      <xd:p>This stylesheet, when applied to mets.xml of the PAGE output, will create (valid) TEI</xd:p>
      <xd:p></xd:p>
      <xd:p><xd:b>Contributor</xd:b> Matthias Boenig, boenig@bbaw.de</xd:p>
      <xd:p>OCR-D, Berlin-Brandenburg Academy of Sciences and Humanities http://ocr-d.de/eng</xd:p>
      <xd:p>extend the original XSL-Stylesheet by specific elements based on the @typing of the text region</xd:p>
      <xd:p></xd:p>
      <xd:p><xd:b>Contributor</xd:b> Peter Stadler, github:@peterstadler</xd:p>
      <xd:p>Carl-Maria-von-Weber-Gesamtausgabe</xd:p>
      <xd:p>Added corrections to tei:sic/tei:corr</xd:p>
      <xd:p></xd:p>
      <xd:p><xd:b>Contributor</xd:b> Till Graller, github:@tillgrallert</xd:p>
      <xd:p>Orient-Institut Beirut</xd:p>
      <xd:p>Use tei:ab as fallback instead of tei:p</xd:p>
      <xd:p><xd:b>Contributor</xd:b> Andreas Wagner, wagner@lhlt.mpg.de, github:@awagner-mainz</xd:p>
      <xd:p>Max Planck Institut for Legal History and Legal Theory</xd:p>
      <xd:p>Process TextRegions in the order specified in the ReadingOrder element; optionally process
        a directory of files rather than a single file; include information from external file with metadata;
        optionally write all files to a directory that can be specified here rather than in the launching
        of the transformation</xd:p>
    </xd:desc>
  </xd:doc>

  <!-- use extended string functions from https://github.com/dariok/XStringUtils -->
  <xsl:include href="string-pack.xsl"/>

  <xsl:param name="debug" select="false()" />

  <!-- use an external file with metadata about the documents -->
  <xsl:variable name="metadaten" select="doc('./metadaten_semantic.xml')"/>
  <xsl:variable name="meta">
    <xsl:variable name="identifier"><!-- our document identifiers are in an ancestor path component, and the depth differs depending on the OCR4all version -->
      <xsl:variable name="v1" select="reverse(tokenize(base-uri(.), '/'))[4]"/>
      <xsl:variable name="v2" select="reverse(tokenize(base-uri(.), '/'))[5]"/>
      <xsl:choose>
        <xsl:when test="matches(substring($v1,1,5), '\d{5}')"><!-- we are at the correct depth if the first 5 characters of the path component are all digits -->
          <xsl:value-of select="$v1"/>
        </xsl:when>
        <xsl:when test="matches(substring($v2,1,5), '\d{5}')">
          <xsl:value-of select="$v2"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:message terminate="yes" select="concat('Cannot find identifier for current document ', base-uri(.), '. Exiting.')"/>
        </xsl:otherwise>
      </xsl:choose>      
    </xsl:variable>   <xsl:variable name="docnumber" select="tokenize($identifier, '_')[1]"/><!-- ... and even that we have to parse! -->
    <xsl:message select="concat('Processing document ', $docnumber, '...')"/>
    <xsl:choose>
      <xsl:when test="$metadaten//*:dokument[@nr eq $docnumber]/kurztitel">
        <xsl:copy-of select="$metadaten//*:dokument[@nr eq $docnumber]"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:message terminate="yes" select="concat('Cannot find metadata for document ', $docnumber, '. Exiting.')"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:variable>

  <xsl:variable name="classifications" select="doc('./taxonomy.xml')"/>
  
  <xd:doc>
    <xd:desc>Entry point: start at the document root and decide about result document</xd:desc>
  </xd:doc>
  <xsl:template match="/">
    <xsl:choose>
      <xsl:when test="$determine_result_document">
        <xsl:result-document href="{$result_doc_path}/{$meta//@nr}.xml" method="xml" indent="no">
          <xsl:call-template name="tei_root"/>
        </xsl:result-document>
        <xsl:message select="concat('Saved at ', $result_doc_path, '/', $meta//@nr, '.xml.')"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:call-template name="tei_root"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xd:doc>
    <xd:desc>This named template constructs the main TEI boilerplace and calls subordinate templates</xd:desc>
  </xd:doc>
  <xsl:template name="tei_root" xml:space="preserve"><xsl:variable name="doc-id" select="concat('NSRMI_', tokenize(tokenize(document-uri(.), '/')[last()-3], '_')[1])"/>
<xsl:processing-instruction name="xml-model"><xsl:text>href="http://www.tei-c.org/release/xml/tei/custom/schema/relaxng/tei_all.rng" type="application/xml" schematypens="http://relaxng.org/ns/structure/1.0"</xsl:text></xsl:processing-instruction>
<xsl:processing-instruction name="xml-model"><xsl:text>href="http://www.tei-c.org/release/xml/tei/custom/schema/relaxng/tei_all.rng" type="application/xml" schematypens="http://purl.oclc.org/dsdl/schematron"</xsl:text></xsl:processing-instruction>
<xsl:processing-instruction name="teipublisher"><xsl:text>template="view-grid.html" view="single"</xsl:text></xsl:processing-instruction>
<TEI xml:id="{$doc-id}">
    <teiHeader>
        <fileDesc>
            <titleStmt><xsl:choose><xsl:when test="./local-name() eq 'mets'">
               <xsl:apply-templates select="mets:amdSec//trpDocMetadata/title | p2017:Metadata/p2017:Title | p2019:Metadata/p2019:Title" />
               <xsl:apply-templates select="mets:amdSec//trpDocMetadata/author | p2017:Metadata/p2017:Creator | p2019:Metadata/p2019:Creator" />
               <xsl:apply-templates select="mets:amdSec//trpDocMetadata/uploader" />
            </xsl:when><xsl:when test="$meta"><xsl:message select="concat('Kurztitel: ', $meta//*:kurztitel)"/>
                <title type="short"><xsl:value-of select="$meta//*:kurztitel/string()"/></title>
                <title type="main"><xsl:value-of select="$meta//*:titel/string()"/></title>
                <xsl:if test="$meta//*:unternehmen | $meta//*:institution"><author><xsl:value-of select="string-join(($meta//*:unternehmen, $meta//*:institution)[. != ''], ' und ')"/></author></xsl:if>
            </xsl:when><xsl:otherwise>
                <xsl:apply-templates select="p2017:Metadata/p2017:Title|p2019:Metadata/p2019:Title" />
                <xsl:apply-templates select="p2017:Metadata/p2017:Creator|p2019:Metadata/p2019:Title" />
            </xsl:otherwise></xsl:choose>
                <editor xml:id="PC" role="#scholarly">
                    <persName ref="gnd:122339479">
                        <surname full="yes">Collin</surname>, <forename full="yes">Peter</forename>
                    </persName>
                </editor>
                <editor xml:id="JW" role="#scholarly">
                    <persName ref="orcid:0000-0001-6364-8902 gnd:1124952586">
                        <surname full="yes">Wolf</surname>, <forename full="yes">Johanna</forename>
                    </persName>
                </editor>
                <editor xml:id="ME" role="#scholarly">
                    <persName ref="orcid:0000-0001-6440-2453">
                        <surname full="yes">Ebbertz</surname>, <forename full="yes">Matthias</forename>
                    </persName>
                </editor>
                <editor xml:id="TV" role="#scholarly">
                    <persName>
                        <surname full="yes">Vesper</surname>, <forename full="yes">Tim</forename>
                    </persName>
                </editor>
                <editor xml:id="AW" role="#technical">
                    <persName ref="orcid:0000-0003-1835-1653">
                        <surname>Wagner</surname>, <forename>Andreas</forename>
                    </persName>
                </editor>
                <editor xml:id="PS" role="#technical">
                    <persName>
                        <surname>Solonets</surname>, <forename>Polina</forename>
                    </persName>
                </editor>
                <editor xml:id="BS" role="#technical">
                    <persName>
                        <surname>Spendrin</surname>, <forename>Benjamin</forename>
                    </persName>
                </editor>
            <editor xml:id="BG" role="#technical">
                    <persName>
                        <surname>Gödde</surname>, <forename>Ben</forename>
                    </persName>
                </editor>
              <editor xml:id="LM" role="#technical">
                    <persName>
                        <surname>Michel</surname>, <forename>Lisa</forename>
                    </persName>
                </editor>
              <editor xml:id="AWt" role="#technical">
                    <persName>
                        <surname>Walther</surname>, <forename>Annika</forename>
                    </persName>
                </editor>
              <editor xml:id="PW" role="#technical">
                    <persName>
                        <surname>Wolf</surname>, <forename>Paulina</forename>
                    </persName>
                </editor>
            </titleStmt>

            <editionStmt>
                <edition n="1.0.0">
                    Complete digital edition, <date type="digitizedEd" when="{current-date()}"><xsl:value-of select="current-date()"/></date>.
                </edition>
            </editionStmt>

            <publicationStmt>
                <publisher xml:id="pubstmt-publisher">
                    <orgName>Max Planck Institute for Legal History and Legal Theory</orgName>
                    <ref type="url" target="http://www.lhlt.mpg.de/">http://www.lhlt.mpg.de/</ref>
                </publisher>
                <distributor xml:id="pubstmt-distributor">
                    <orgName>Max Planck Institute for Legal History and Legal Theory</orgName>
                    <ref type="url" target="http://www.lhlt.mpg.de/">http://www.lhlt.mpg.de/</ref>
                </distributor>
                <pubPlace role="digitizedEd" xml:id="pubstmt-pubplace">
                    Frankfurt am Main, Germany
                </pubPlace>
                <availability xml:id="pubstmt-availability">
                    <licence target="https://creativecommons.org/licenses/by/4.0" n="cc-by">
                        <p xml:id="p_ffjaztskfd">This work or content, respectively, was created for the Max Planck Institute for Legal
                            History and Legal Theory, Frankfurt/M., and is licensed under the terms of a
                            <ref target="http://creativecommons.org/licenses/by/4.0/">Creative Commons Attribution 4.0 International (CC BY 4.0)</ref>.</p>
                    </licence>
                </availability>
                <date type="digitizedEd" when="{current-date()}"><xsl:value-of select="current-date()"/></date>
            </publicationStmt>

            <seriesStmt xml:id="seriesStmt">
                <title level="s">Nichtstaatliches Recht der Wirtschaft</title>
                <editor ref="#PC"/>
                <editor ref="#JW"/>
            </seriesStmt><xsl:if test="string-length(normalize-space($meta//*:kommentar)) gt 0">

            <notesStmt>
                <note><xsl:value-of select="normalize-space($meta//*:kommentar)"/></note>
            </notesStmt></xsl:if>

            <sourceDesc>
                <xsl:if test="$meta"><bibl>
                    <xsl:if test="string-length(normalize-space(string-join($meta//*:unternehmen | $meta//*:institution))) gt 0"><author><xsl:value-of select="string-join(($meta//*:unternehmen, $meta//*:institution)[. != ''], ' und ')"/></author></xsl:if>
                    <xsl:if test="string-length(normalize-space($meta//*:jahr)) gt 0"><date when="{if (string(number($meta//*:jahr)) != 'NaN') then $meta//*:jahr/string() else ()}"><xsl:value-of select="$meta//*:jahr/string()"/></date></xsl:if><xsl:if test="string-length(normalize-space($meta//*:stadt)) gt 0">
                    <pubPlace ana="nsrmi:city"   key="{$meta//*:stadt/string()}"><xsl:value-of select="$meta//*:stadt/string()"/></pubPlace></xsl:if><xsl:if test="string-length(normalize-space($meta//*:region)) gt 0">
                    <pubPlace ana="nsrmi:region" key="{$meta//*:region/string()}"><xsl:value-of select="$meta//*:region/string()"/></pubPlace></xsl:if><xsl:if test="string-length(normalize-space($meta//*:nachweis)) gt 0">
                    <note>According to: <bibl><xsl:value-of select="$meta//*:nachweis/string()"/></bibl></note></xsl:if>
                </bibl>
                <xsl:if test="string-length(normalize-space(string-join($meta//*:archiv | $meta//*:bestand | $meta//*:signatur))) gt 0"><msDesc>
                    <msIdentifier><xsl:if test="string-length(normalize-space($meta//*:archiv)) gt 0">
                        <institution><xsl:value-of select="$meta//*:archiv/string()"/></institution></xsl:if><xsl:if test="string-length(normalize-space($meta//*:bestand)) gt 0">
                        <collection><xsl:value-of select="$meta//*:bestand/string()"/></collection></xsl:if><xsl:if test="string-length(normalize-space($meta//*:signatur)) gt 0">
                        <idno><xsl:value-of select="$meta//*:signatur/string()"/></idno></xsl:if>
                    </msIdentifier>
                </msDesc></xsl:if></xsl:if><xsl:if test="mets:amdSec//uploader"><p>TRP document creator: <xsl:value-of select="mets:amdSec//uploader"/></p></xsl:if>
                <xsl:apply-templates select="mets:amdSec//trpDocMetadata/desc" />
            </sourceDesc>
        </fileDesc>

        <encodingDesc>
            <listPrefixDef>
                <prefixDef ident="nsrmi" matchPattern="([A-z0-9.:#_\-]+)" replacementPattern="http://c100-172.cloud.gwdg.de:8080/exist/apps/metallindustrie/api/document/taxonomy.xml#$1">
                   <p xml:id="p_f2q34f3cew" xml:lang="en">Within the scope of this edition, pointers using an &quot;nsrmi&quot; prefix are private URIs and refer to 
                       taxonomies and entity description defined in the &quot;taxonomy.xml&quot; file in the &quot;metall-data&quot; directory of this app.
                       These definitions can accessed via web
                       under the address <ref type="url" target="http://c100-172.cloud.gwdg.de:8080/exist/apps/metallindustrie/api/document/taxonomy.xml">http://c100-172.cloud.gwdg.de:8080/exist/apps/metallindustrie/api/document/taxonomy.xml</ref>, 
                       which is to be complemented by the identifier (what comes after the &quot;nsrmi:&quot; prefix), prepended by a &quot;#&quot; passage identifier, e.g.
                       <ref type="url" target="http://c100-172.cloud.gwdg.de:8080/exist/apps/metallindustrie/api/document/taxonomy.xml#kategorie">http://c100-172.cloud.gwdg.de:8080/exist/apps/metallindustrie/api/document/taxonomy.xml#kategorie</ref>.</p>
                </prefixDef>
            </listPrefixDef>
        </encodingDesc>

        <xsl:if test="string-length(normalize-space(string-join($meta//*:branche | $meta//*:key | $meta//*:kategorie))) gt 0"><profileDesc>
            <textClass><xsl:if test="string-length(normalize-space($meta//*:kategorie)) gt 0">
               <catRef scheme="nsrmi:kategorie" target="nsrmi:{$classifications//tei:category[./tei:catDesc/string() = $meta//*:kategorie/string()]/@xml:id/string()}"/></xsl:if><xsl:if test="string-length(normalize-space($meta//*:branche)) gt 0">
               <catRef scheme="nsrmi:branche" target="nsrmi:{$classifications//tei:category[./tei:catDesc/string() = $meta//*:branche/string()]/@xml:id/string()}"/></xsl:if><xsl:if test="string-length(normalize-space($meta//*:key)) gt 0">
               <catRef scheme="nsrmi:key" target="nsrmi:{$classifications//tei:category[./tei:catDesc/@key/string() = $meta//*:key/string()]/@xml:id/string()}"/></xsl:if>
            </textClass>
        </profileDesc></xsl:if>

        <revisionDesc>
            <listChange>
                <change when="{current-date()}" who="#auto #AW">Compile TEI from PageXML sources</change>
            </listChange>
        </revisionDesc>
    </teiHeader><xsl:choose><xsl:when test="$directory_mode">
<xsl:apply-templates mode="rootcopyFacs"/>
      </xsl:when><xsl:otherwise><xsl:if test="not($debug)">
<xsl:apply-templates select="mets:mets | p2017:PcGts | p2019:PcGts" mode="facs"/>
        </xsl:if></xsl:otherwise></xsl:choose>
    <text>
        <body><xsl:choose><xsl:when test="$directory_mode"><xsl:apply-templates mode="rootcopyText"/></xsl:when><xsl:otherwise><xsl:apply-templates select="mets:mets | p2017:PcGts | p2019:PcGts" mode="text"/></xsl:otherwise></xsl:choose>
        </body>
    </text>
</TEI>
  </xsl:template>

  <xd:doc>
    <xd:desc>If necessary, get all root nodes from other files for facsimile construction</xd:desc>
  </xd:doc>
  <xsl:template match="node()" mode="rootcopyFacs">
      <xsl:variable name="folderURI" select="resolve-uri('.',base-uri())"/>
      <xsl:for-each select="collection(concat($folderURI, '?select=*.xml;recurse=yes'))">
          <xsl:sort select="tokenize(document-uri(.), '/')[last()]"/>
          <xsl:apply-templates select="//mets:mets | //p2017:PcGts | //p2019:PcGts" mode="facs"/>
      </xsl:for-each>
  </xsl:template>

  <xd:doc>
    <xd:desc>If necessary, get all root nodes from other files for text construction</xd:desc>
  </xd:doc>
  <xsl:template match="node()" mode="rootcopyText">
    <xsl:variable name="folderURI" select="resolve-uri('.',base-uri())"/>
    <xsl:for-each select="collection(concat($folderURI, '?select=*.xml;recurse=yes'))">
        <xsl:sort select="tokenize(document-uri(.), '/')[last()]"/>
        <xsl:apply-templates select="//mets:mets | //p2017:PcGts | //p2019:PcGts" mode="text"/>
    </xsl:for-each>
  </xsl:template>


  <xd:doc>
    <xd:desc>root element of single files, create text</xd:desc>
  </xd:doc>
  <xsl:template match="mets:mets | p2017:PcGts | p2019:PcGts" mode="text">
    <xsl:variable name="make_div">
      <div>
        <xsl:choose><xsl:when test="./local-name() eq 'mets'">
            <xsl:apply-templates select="mets:fileSec//mets:fileGrp[@ID='PAGEXML']/mets:file" mode="text">
              <xsl:with-param name="numCurr" select="xs:integer(xstring:substring-before(p2017:Page/@imageFilename | p2019:Page/@imageFilename, '.png'))" tunnel="true" />
            </xsl:apply-templates>
        </xsl:when><xsl:otherwise>
            <xsl:apply-templates select="p2017:Page|p2019:Page" mode="text">
              <xsl:with-param name="numCurr" select="xs:integer(xstring:substring-before(p2017:Page/@imageFilename | p2019:Page/@imageFilename, '.png'))" tunnel="true" />
            </xsl:apply-templates>
        </xsl:otherwise></xsl:choose>
      </div></xsl:variable>
    <xsl:for-each-group select="$make_div//*[local-name() = 'div']/*" group-starting-with="*[local-name() = 'head']" xml:space="preserve">
            <div xmlns="http://www.tei-c.org/ns/1.0">
                <xsl:copy-of select="current-group()"/>
            </div></xsl:for-each-group>
  </xsl:template>

  <xd:doc>
    <xd:desc>root element of single files, create facsimile</xd:desc>
  </xd:doc>
  <xsl:template match="mets:mets | p2017:PcGts | p2019:PcGts" mode="facs"><xsl:if test="not($debug)" xml:space="preserve">
    <facsimile><xsl:choose><xsl:when test="./local-name() eq 'mets'">
        <xsl:apply-templates select="mets:fileSec//mets:fileGrp[@ID='PAGEXML']/mets:file" mode="facsimile"/>
    </xsl:when><xsl:otherwise><xsl:message select="concat('__Facsimile: Page ', xstring:substring-before(p2017:Page/@imageFilename | p2019:Page/@imageFilename, '.png'))"/>
        <xsl:apply-templates select="p2017:Page|p2019:Page" mode="facsimile">
          <xsl:with-param name="numCurr" select="xs:integer(xstring:substring-before(p2017:Page/@imageFilename | p2019:Page/@imageFilename, '.png'))"  tunnel="true"/>
          <xsl:with-param name="imageName" select="p2017:Page/@imageFilename | p2019:Page/@imageFilename"  tunnel="true"/>
        </xsl:apply-templates>
    </xsl:otherwise></xsl:choose></facsimile></xsl:if>
  </xsl:template>


  <!-- Templates for trpMetaData -->
  <xd:doc>
    <xd:desc>
      <xd:p>The title within the Transkribus meta data</xd:p>
    </xd:desc>
  </xd:doc>
  <xsl:template match="title">
    <title>
      <xsl:if test="position() = 1">
        <xsl:attribute name="type">main</xsl:attribute>
      </xsl:if>
      <xsl:apply-templates />
    </title>
  </xsl:template>

  <xd:doc>
    <xd:desc>The author as stated in Transkribus meta data.
      Will be used in the teiHeader as titleStmt/author</xd:desc>
  </xd:doc>
  <xsl:template match="author">
    <author>
      <xsl:apply-templates />
    </author>
  </xsl:template>

  <xd:doc>
    <xd:desc>The uploader of the current document.
      Will be used as titleStmt/principal</xd:desc>
  </xd:doc>
  <xsl:template match="uploader">
    <principal><xsl:apply-templates /></principal>
  </xsl:template>

  <xd:doc>
    <xd:desc>The description as given in Transkribus meta data.
      Will be used in sourceDesc</xd:desc>
  </xd:doc>
  <xsl:template match="desc">
    <p><xsl:apply-templates /></p>
  </xsl:template>

  <xd:doc>
    <xd:desc>The name of the collection from which this document was exported.
      Will be used as seriesStmt/title</xd:desc>
  </xd:doc>
  <xsl:template match="colName">
    <title><xsl:apply-templates /></title>
  </xsl:template>

  <!-- Templates for METS -->
  <xd:doc>
    <xd:desc>Create tei:facsimile with @xml:id</xd:desc>
  </xd:doc>
  <xsl:template match="mets:file" mode="facsimile">
    <xsl:variable name="file" select="document(mets:FLocat/@xlink:href, /)"/>
    <xsl:variable name="numCurr" select="@SEQ"/>
    
    <xsl:apply-templates select="$file//p2017:Page | $file//p2019:Page" mode="facsimile">
      <xsl:with-param name="imageName" select="substring-after(mets:FLocat/@xlink:href, '/')" />
      <xsl:with-param name="numCurr" select="$numCurr" tunnel="true" />
    </xsl:apply-templates>
  </xsl:template>

  <xd:doc>
    <xd:desc>Apply by-page</xd:desc>
  </xd:doc>
  <xsl:template match="mets:file" mode="text">
    <xsl:variable name="file" select="document(mets:FLocat/@xlink:href, .)"/>
    <xsl:variable name="numCurr" select="@SEQ"/>
    
    <xsl:apply-templates select="$file//p2017:Page | $file//p2019:Page" mode="text">
      <xsl:with-param name="numCurr" select="$numCurr" tunnel="true" />
    </xsl:apply-templates>
  </xsl:template>

  <!-- Templates for PAGE, facsimile -->
  <xd:doc>
    <xd:desc>
      <xd:p>Create tei:facsimile/tei:surface</xd:p>
    </xd:desc>
    <xd:param name="imageName">
      <xd:p>the file name of the image</xd:p>
    </xd:param>
    <xd:param name="numCurr">
      <xd:p>Numerus currens of the parent facsimile</xd:p>
    </xd:param>
  </xd:doc>
  <xsl:template match="p2017:Page|p2019:Page" mode="facsimile">
    <xsl:param name="imageName" tunnel="true"/>
    <xsl:param name="numCurr" tunnel="true" />
    <xsl:variable name="coords" select="tokenize(p2017:PrintSpace/p2017:Coords/@points | p2019:PrintSpace/p2019:Coords/@points, ' ')" />
    <xsl:variable name="type" select="substring-after(@imageFilename, '.')" />
    <!-- NOTE: up to now, lry and lry were mixed up. This is fixed here. -->
<surface ulx="0" uly="0"
      lrx="{@imageWidth}" lry="{@imageHeight}"
      xml:id="facs_{$numCurr}" xml:space="preserve">
            <graphic url="{encode-for-uri(substring-before($imageName, '.'))||'.'||$type}" width="{@imageWidth}px" height="{@imageHeight}px"/>
            <xsl:apply-templates select="p2017:PrintSpace | p2019:PrintSpace | p2017:TextRegion | p2019:TextRegion | p2017:SeparatorRegion | p2019:SeparatorRegion | p2017:GraphicRegion | p2019:GraphicRegion | p2017:TableRegion | p2019:TableRegion" mode="facsimile"/>
</surface>
  </xsl:template>

  <xd:doc>
    <xd:desc>create the zones within facsimile/surface</xd:desc>
    <xd:param name="numCurr">Numerus currens of the current page</xd:param>
  </xd:doc>
  <xsl:template match="p2017:PrintSpace | p2019:PrintSpace | p2017:TextRegion | p2019:TextRegion | p2017:SeparatorRegion | p2019:SeparatorRegion | p2017:GraphicRegion | p2019:GraphicRegion | p2017:TextLine | p2019:TextLine" mode="facsimile">
    <xsl:param name="numCurr" tunnel="true" />
    <xsl:variable name="renditionValue">
      <xsl:choose>
        <xsl:when test="local-name(parent::*) = 'TableCell'">TableCell</xsl:when>
        <xsl:when test="local-name() = 'TextRegion'">TextRegion</xsl:when>
        <xsl:when test="local-name() = 'SeparatorRegion'">Separator</xsl:when>
        <xsl:when test="local-name() = 'GraphicRegion'">Graphic</xsl:when>
        <xsl:when test="local-name() = 'TextLine'">Line</xsl:when>
        <xsl:otherwise>printspace</xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="custom" as="map(xs:string, xs:string)">
      <xsl:map>
        <xsl:for-each-group select="tokenize(@custom||' lfd {'||$numCurr, '\} ')" group-by="substring-before(., ' ')">
          <xsl:map-entry key="substring-before(., ' ')" select="string-join(substring-after(., '{'), '–')" />
        </xsl:for-each-group>
      </xsl:map>
    </xsl:variable>
    <xsl:if test="$renditionValue = ('Line', 'TableCell')">
<xsl:text>
        </xsl:text>
    </xsl:if>
    <zone points="{p2017:Coords/@points | p2019:Coords/@points}" rendition="{$renditionValue}">
      <xsl:if test="$renditionValue != 'printspace'"><xsl:attribute name="xml:id"><xsl:value-of select="'facs_'||$numCurr||'_'||@id"/></xsl:attribute></xsl:if>
      <xsl:if test="@type"><xsl:if test="$renditionValue = 'TextRegion'"><xsl:attribute name="type">text</xsl:attribute></xsl:if><xsl:attribute name="subtype"><xsl:value-of select="@type"/></xsl:attribute></xsl:if>
      <xsl:if test="map:contains($custom, 'structure') and not(@type)"><xsl:attribute name="subtype" select="substring-after(substring-before(map:get($custom, 'structure'), ';'), ':')" /></xsl:if>
        <xsl:apply-templates select="p2017:TextLine | p2019:TextLine" mode="facsimile" />
        <xsl:if test="not($renditionValue= ('Line', 'Graphic', 'Separator', 'printspace', 'TableCell'))">
            <xsl:text>
</xsl:text>
        </xsl:if>
    </zone>
  </xsl:template>

  <xd:doc>
    <xd:desc>Create the zone for a table</xd:desc>
    <xd:param name="numCurr">Numerus currens of the current page</xd:param>
  </xd:doc>
  <xsl:template match="p2017:TableRegion | p2019:TableRegion" mode="facsimile">
    <xsl:param name="numCurr" tunnel="true" />
    
    <zone points="{p2017:Coords/@points | p2019:Coords/@points}" rendition="Table">
      <xsl:attribute name="xml:id"><xsl:value-of select="'facs_'||$numCurr||'_'||@id"/></xsl:attribute>
      <xsl:apply-templates select="p2017:TableCell//p2017:TextLine | p2019:TableCell//p2019:TextLine" mode="facsimile" />
    </zone>
  </xsl:template>

  <xd:doc>
    <xd:desc>create the page content</xd:desc>
    <xd:param name="numCurr">Numerus currens of the current page</xd:param>
  </xd:doc>
  <!-- Templates for PAGE, text -->
  <xsl:template match="p2017:Page | p2019:Page" mode="text">
    <xsl:param name="numCurr" tunnel="true" />
    <pb facs="#facs_{$numCurr}" n="{$numCurr}" xml:id="img_{format-number($numCurr, '0000')}"/>
    <xsl:choose>
      <xsl:when test="p2017:ReadingOrder/p2017:OrderedGroup/p2017:RegionRefIndexed/@regionRef | p2019:ReadingOrder/p2019:OrderedGroup/p2019:RegionRefIndexed/@regionRef">
        <xsl:variable name="pg" select="." />
        <xsl:variable name="readingOrder">
          <xsl:if test="$debug"><xsl:message><xsl:value-of select="'Reading Order enthält ' || count(p2017:ReadingOrder/p2017:OrderedGroup/p2017:RegionRefIndexed/@regionRef | p2019:ReadingOrder/p2019:OrderedGroup/p2019:RegionRefIndexed/@regionRef) || ' Elemente: ' || string-join(p2017:ReadingOrder/p2017:OrderedGroup/p2017:RegionRefIndexed/@regionRef | p2019:ReadingOrder/p2019:OrderedGroup/p2019:RegionRefIndexed/@regionRef, ', ')"/></xsl:message></xsl:if>
          <xsl:value-of select="string-join(p2017:ReadingOrder/p2017:OrderedGroup/p2017:RegionRefIndexed/@regionRef | p2019:ReadingOrder/p2019:OrderedGroup/p2019:RegionRefIndexed/@regionRef, ' ')"/>
        </xsl:variable>
        <xsl:variable name="orderedRegions" as="node()*">
          <xsl:for-each select="tokenize($readingOrder, ' ')">
            <xsl:variable name="t" select="."/>
            <xsl:copy-of select="$pg/p2017:TextRegion[@id = $t] | $pg/p2019:TextRegion[@id = $t] | $pg/p2017:SeparatorRegion[@id = $t] | $pg/p2019:SeparatorRegion[@id = $t] | $pg/p2017:GraphicRegion[@id = $t] | $pg/p2019:GraphicRegion[@id = $t] | $pg/p2017:TableRegion[@id = $t] | $pg/p2019:TableRegion[@id = $t]"/>
          </xsl:for-each>
        </xsl:variable>
        
        <xsl:for-each select="$orderedRegions">
          <xsl:message select="'__TextRegion: Page ' || format-number($numCurr, '0000') || ', region ' || ./@id/string()"/>
          <xsl:apply-templates select="." mode="text"/>
        </xsl:for-each>
      </xsl:when><xsl:otherwise>
        <xsl:apply-templates select="p2017:TextRegion | p2019:TextRegion | p2017:SeparatorRegion | p2019:SeparatorRegion | p2017:GraphicRegion | p2019:GraphicRegion | p2017:TableRegion | p2019:TableRegion" mode="text" />
      </xsl:otherwise></xsl:choose>
  </xsl:template>

  <xd:doc>
   <xd:desc>
    <xd:p>create specific elements based on the @typing of the text region</xd:p>
    <xd:p>PAGE labels for text region see: https://www.primaresearch.org/tools/PAGELibraries
     caption observed 
     header observed 
     footer observed 
     page-number observed 
     drop-capital ignored
     credit observed
     floating ignored
     signature-mark observed 
     catch-word observed 
     marginalia observed 
     footnote observed 
     footnote-continued observed
     endnote ignored
     TOC-entry ignored
     list-label ignored
     other observed
    </xd:p></xd:desc>
    <xd:param name="numCurr"/>
  </xd:doc>
  <xsl:template match="p2017:TextRegion | p2019:TextRegion" mode="text">
    <xsl:param name="numCurr" tunnel="true" />
    <xsl:variable name="custom" as="map(*)">
      <xsl:choose>
        <xsl:when test="@custom">
          <xsl:apply-templates select="@custom"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:map><xsl:map-entry key="'key'" select="'value'" /></xsl:map>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    
    <xsl:choose>
      <xsl:when test="@type = 'heading'">
        <head facs="#facs_{$numCurr}_{@id}">
          <xsl:apply-templates select="p2017:TextLine | p2019:TextLine" />
        </head>
      </xsl:when>
      <xsl:when test="@type = 'caption'">
        <figure>
          <head facs="#facs_{$numCurr}_{@id}"><xsl:apply-templates select="p2017:TextLine | p2019:TextLine" /></head>
        </figure>
      </xsl:when>
      <xsl:when test="@type = 'header'">
        <fw type="header" place="top" facs="#facs_{$numCurr}_{@id}"><xsl:apply-templates select="p2017:TextLine | p2019:TextLine" /></fw>
      </xsl:when>
      <xsl:when test="@type = 'footer'">
        <fw type="header" place="bottom" facs="#facs_{$numCurr}_{@id}"><xsl:apply-templates select="p2017:TextLine | p2019:TextLine" /></fw>
      </xsl:when>
      <xsl:when test="@type = 'catch-word'">
        <fw type="catch" place="bottom" facs="#facs_{$numCurr}_{@id}"><xsl:apply-templates select="p2017:TextLine | p2019:TextLine" /></fw>
      </xsl:when>
      <xsl:when test="@type = 'signature-mark'">
        <fw place="bottom" type="sig" facs="#facs_{$numCurr}_{@id}"><xsl:apply-templates select="p2017:TextLine | p2019:TextLine" /></fw>
      </xsl:when>
      <xsl:when test="@type = 'marginalia'">
        <note place="[direction]" facs="#facs_{$numCurr}_{@id}"><xsl:apply-templates select="p2017:TextLine | p2019:TextLine" /></note>
      </xsl:when>
      <xsl:when test="@type = 'footnote'">
        <note place="bottom" n="[footnote reference]" facs="#facs_{$numCurr}_{@id}"><xsl:apply-templates select="p2017:TextLine | p2019:TextLine" /></note>
      </xsl:when>
      <xsl:when test="@type = 'footnote-continued'">
        <note place="bottom" n="[footnote-continued reference]" facs="#facs_{$numCurr}_{@id}"><xsl:apply-templates select="p2017:TextLine | p2019:TextLine" /></note>
      </xsl:when>
      <xsl:when test="@type = ('other', 'paragraph')">
        <p facs="#facs_{$numCurr}_{@id}">
          <xsl:apply-templates select="p2017:TextLine | p2019:TextLine" />
        </p>
      </xsl:when>
      <xsl:when test="@type = 'credit'">
          <div type="paratext" facs="#facs_{$numCurr}_{@id}">
              <p facs="#facs_{$numCurr}_{@id}">
                <xsl:apply-templates select="p2017:TextLine | p2019:TextLine" />
              </p>
          </div>
      </xsl:when>
      <!-- the fallback option should be a semantically open element such as <ab> -->
      <xsl:otherwise>
        <ab facs="#facs_{$numCurr}_{@id}" type="{@type}{$custom?structure?type}">
          <xsl:apply-templates select="p2017:TextLine | p2019:TextLine" />
        </ab>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xd:doc>
    <xd:desc>create a table</xd:desc>
    <xd:param name="numCurr"/>
  </xd:doc>
  <xsl:template match="p2017:TableRegion | p2019:TableRegion" mode="text">
    <xsl:param name="numCurr" tunnel="true" />
    <xsl:text>
      </xsl:text>
    <table facs="#facs_{$numCurr}_{@id}">
      <xsl:for-each-group select="p2017:TableCell | p2019:TableCell" group-by="@row">
        <xsl:sort select="@col" />
        <xsl:text>
        </xsl:text>
        <row n="{@row}">
          <xsl:apply-templates select="current-group()" />
        </row>
      </xsl:for-each-group>
    </table>
  </xsl:template>

  <xd:doc>
    <xd:desc>create table cells</xd:desc>
    <xd:param name="numCurr"/>
  </xd:doc>
  <xsl:template match="p2017:TableCell | p2019:TableCell">
    <xsl:param name="numCurr" tunnel="true" />
    <xsl:text>
          </xsl:text>
    <cell facs="#facs_{$numCurr}_{@id}" n="{@col}">
      <xsl:apply-templates select="@rowSpan | @colSpan" />
      <xsl:attribute name="rend">
        <xsl:value-of select="number((xs:boolean(@leftBorderVisible), false())[1])" />
        <xsl:value-of select="number((xs:boolean(@topBorderVisible), false())[1])" />
        <xsl:value-of select="number((xs:boolean(@rightBorderVisible), false())[1])" />
        <xsl:value-of select="number((xs:boolean(@bottomBorderVisible), false())[1])" />
      </xsl:attribute>
      <xsl:apply-templates select="p2017:TextLine | p2019:TextLine" />
    </cell>
  </xsl:template>
  <xd:doc>
    <xd:desc>rowspan -> rows</xd:desc>
  </xd:doc>
  <xsl:template match="@rowSpan">
    <xsl:choose>
      <xsl:when test=". &gt; 1">
        <xsl:attribute name="rows" select="." />
      </xsl:when>
    </xsl:choose>
  </xsl:template>
  <xd:doc>
    <xd:desc>colspan -> cols</xd:desc>
  </xd:doc>
  <xsl:template match="@colSpan">
    <xsl:choose>
      <xsl:when test=". &gt; 1">
        <xsl:attribute name="cols" select="." />
      </xsl:when>
    </xsl:choose>
  </xsl:template>

  <xd:doc>
    <xd:desc>
      Combine taggings marked with “continued” – cf. https://github.com/dariok/page2tei/issues/10
      Thanks to @thodel for reporting.
    </xd:desc>
    <xd:param name="context" />
  </xd:doc>
  <xsl:template name="continuation">
    <xsl:param name="context" />
    <xsl:for-each select="$context/node()">
      <xsl:choose>
        <xsl:when test="@continued
          and following-sibling::*[1][self::tei:lb]
          and string-length(normalize-space(following-sibling::node()[1])) = 0">
          <xsl:element name="{local-name()}">
            <xsl:sequence select="@*[not(local-name() = 'continued')]" />
            <xsl:sequence select="node()" />
            <lb>
              <xsl:sequence select="following-sibling::*[1]/@*" />
              <xsl:attribute name="break" select="'no'" />
            </lb>
            <xsl:sequence select="following-sibling::*[2]/node()" />
          </xsl:element>
        </xsl:when>
        <xsl:when test="(self::tei:lb
            and preceding-sibling::*[1]/@continued
            and string-length(normalize-space(preceding-sibling::node()[1])) = 0
            and following-sibling::node()[1]/@continued)
          or (@continued and preceding-sibling::node()[1][self::tei:lb])
          or (self::text()
            and normalize-space() = ''
            and preceding-sibling::node()[1]/@continued
            and following-sibling::node()[1][self::tei:lb])" />
        <xsl:otherwise>
          <xsl:sequence select="." />
        </xsl:otherwise>
      </xsl:choose>
    </xsl:for-each>
  </xsl:template>

  <xd:doc>
    <xd:desc>Converts one line of PAGE to one line of TEI</xd:desc>
    <xd:param name="numCurr">Numerus currens, to be tunneled through from the page level</xd:param>
  </xd:doc>
  <xsl:template match="p2017:TextLine | p2019:TextLine">
    <xsl:param name="numCurr" tunnel="true" />
    <xsl:variable name="indexToUse" select="xs:string(min(p2017:TextEquiv/@index | p2019:TextEquiv/@index))"/>
    <xsl:variable name="text" select="p2017:TextEquiv[@index=$indexToUse]/p2017:Unicode | p2019:TextEquiv[@index=$indexToUse]/p2019:Unicode"/>
    <xsl:if test="$debug">
      <xsl:message select="concat('input line: ', $text)"/>
    </xsl:if>
    <xsl:variable name="custom" as="text()*">
      <xsl:for-each select="tokenize(@custom, '\}')">
        <xsl:choose>
          <xsl:when test="string-length() &lt; 1 or starts-with(., 'readingOrder') or starts-with(normalize-space(), 'structure')" />
          <xsl:otherwise>
            <xsl:value-of select="normalize-space()"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:for-each>
    </xsl:variable>
    <xsl:variable name="starts" as="map(*)">
      <xsl:map>
        <xsl:if test="count($custom) &gt; 0">
          <xsl:for-each-group select="$custom" group-by="substring-before(substring-after(., 'offset:'), ';')">
            <xsl:map-entry key="xs:int(current-grouping-key())" select="current-group()" />
          </xsl:for-each-group>
        </xsl:if>
      </xsl:map>
    </xsl:variable>
    <xsl:variable name="ends" as="map(*)">
      <xsl:map>
        <xsl:if test="count($custom) &gt; 0">
          <xsl:for-each-group select="$custom" group-by="xs:int(substring-before(substring-after(., 'offset:'), ';'))
            + xs:int(substring-before(substring-after(., 'length:'), ';'))">
            <xsl:map-entry key="current-grouping-key()" select="current-group()" />
          </xsl:for-each-group>
        </xsl:if>
      </xsl:map>
    </xsl:variable>
    <xsl:variable name="prepped">
      <xsl:for-each select="0 to string-length($text)">
        <xsl:if test=". &gt; 0"><xsl:value-of select="substring($text, ., 1)"/></xsl:if>
        <xsl:for-each select="map:get($starts, .)">
          <!--<xsl:sort select="substring-before(substring-after(.,'offset:'), ';')" order="ascending"/>-->
          <!-- end of current tag -->
          <xsl:sort select="xs:int(substring-before(substring-after(., 'offset:'), ';'))
            + xs:int(substring-before(substring-after(., 'length:'), ';'))" order="descending" />
          <xsl:sort select="substring(., 1, 3)" order="ascending" />
          <xsl:element name="local:m">
            <xsl:attribute name="type" select="normalize-space(substring-before(., ' '))" />
            <xsl:attribute name="o" select="substring-after(., 'offset:')" />
            <xsl:attribute name="pos">s</xsl:attribute>
          </xsl:element>
        </xsl:for-each>
        <xsl:for-each select="map:get($ends, .)">
          <xsl:sort select="substring-before(substring-after(.,'offset:'), ';')" order="descending"/>
          <xsl:sort select="substring(., 1, 3)" order="descending"/>
          <xsl:element name="local:m">
            <xsl:attribute name="type" select="normalize-space(substring-before(., ' '))" />
            <xsl:attribute name="o" select="substring-after(., 'offset:')" />
            <xsl:attribute name="pos">e</xsl:attribute>
          </xsl:element>
        </xsl:for-each>
      </xsl:for-each>
    </xsl:variable>
    <xsl:variable name="prepared">
      <xsl:for-each select="$prepped/node()">
        <xsl:choose>
          <xsl:when test="@pos = 'e'">
            <xsl:variable name="position" select="count(preceding-sibling::node())" />
            <xsl:variable name="o" select="@o" />
            <xsl:variable name="id" select="@type" />
            <xsl:variable name="precs"
              select="preceding-sibling::local:m[@pos = 's' and preceding-sibling::local:m[@o = $o]]" />
            
            <xsl:for-each select="$precs">
              <xsl:variable name="so" select="@o"/>
              <xsl:variable name="myP" select="count(following-sibling::local:m[@pos='e' and @o=$so]/preceding-sibling::node())"/>
              <xsl:if test="following-sibling::local:m[@pos = 'e' and @o=$so
                and $myP &gt; $position] and not(@type = $id)">
                <local:m type="{@type}" pos="e" o="{@o}" prev="{$myP||'.'||$position||($myP > $position)}" />
              </xsl:if>
            </xsl:for-each>
            <xsl:sequence select="." />
            <xsl:for-each select="$precs">
              <xsl:variable name="so" select="@o"/>
              <xsl:variable name="myP" select="count(following-sibling::local:m[@pos='e' and @o=$so]/preceding-sibling::node())"/>
              <xsl:if test="following-sibling::local:m[@pos = 'e' and @o=$so
                and $myP &gt; $position] and not(@type = $id)">
                <local:m type="{@type}" pos="s" o="{@o}" prev="{$myP||'.'||$position||($myP > $position)}" />
              </xsl:if>
            </xsl:for-each>
          </xsl:when>
          <xsl:otherwise>
            <xsl:sequence select="." />
          </xsl:otherwise>
        </xsl:choose>
      </xsl:for-each>
    </xsl:variable>
    
    
    <xsl:variable name="pos">
      <xsl:choose>
        <xsl:when test="contains(@custom, 'index:')">
          <xsl:value-of select="xs:integer(substring-before(substring-after(@custom, 'index:'), ';')) + 1"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="xs:integer(0)"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable> 
    
    <!-- TODO parameter to create <l>...</l> - #1 -->
    <xsl:text>
      </xsl:text>
              <lb facs="#facs_{$numCurr}_{@id}" n="N{format-number($pos, '000')}"/>
    <xsl:apply-templates select="$prepared/text()[not(preceding-sibling::local:m)]" />
    <xsl:apply-templates select="$prepared/local:m[@pos='s']
      [count(preceding-sibling::local:m[@pos='s']) = count(preceding-sibling::local:m[@pos='e'])]" />
      <!--[not(preceding-sibling::local:m[1][@pos='s'])]" />-->
  </xsl:template>

  <xd:doc>
    <xd:desc>Starting milestones for (possibly nested) elements</xd:desc>
  </xd:doc>
  <xsl:template match="local:m[@pos='s']">
    <xsl:variable name="o" select="@o"/>
    <xsl:variable name="custom" as="map(*)">
      <xsl:map>
        <xsl:variable name="t" select="tokenize(@o, ';')"/>
        <xsl:if test="count($t) &gt; 1">
          <xsl:for-each select="$t[. != '']">
            <xsl:map-entry key="normalize-space(substring-before(., ':'))" select="normalize-space(substring-after(., ':'))" />
          </xsl:for-each>
        </xsl:if>
      </xsl:map>
    </xsl:variable>
    
    <xsl:variable name="elem">
      <local:t>
        <xsl:sequence select="following-sibling::node()
          intersect following-sibling::local:m[@o=$o]/preceding-sibling::node()" />
      </local:t>
    </xsl:variable>
    
    <xsl:choose>
      <xsl:when test="@type = 'textStyle'">
        <hi rend="{xstring:substring-before-if-ends(substring-after(substring-after(@o, 'length'), ';'), '}')}">
          <xsl:call-template name="elem">
            <xsl:with-param name="elem" select="$elem" />
          </xsl:call-template>
        </hi>
      </xsl:when>
      <xsl:when test="@type = 'supplied'">
        <supplied reason="">
          <xsl:call-template name="elem">
            <xsl:with-param name="elem" select="$elem" />
          </xsl:call-template>
        </supplied>
      </xsl:when>
      <xsl:when test="@type = 'abbrev'">
        <choice>
          <expan><xsl:value-of select="replace(map:get($custom, 'expansion'), '\\u0020', ' ')"/></expan>
          <abbr>
            <xsl:call-template name="elem">
              <xsl:with-param name="elem" select="$elem" />
            </xsl:call-template>
          </abbr>
        </choice>
      </xsl:when>
      <xsl:when test="@type = 'sic'">
        <choice>
          <corr><xsl:value-of select="replace(map:get($custom, 'correction'), '\\u0020', ' ')"/></corr>
          <sic>
            <xsl:call-template name="elem">
              <xsl:with-param name="elem" select="$elem" />
            </xsl:call-template>
          </sic>
        </choice>
      </xsl:when>
      <xsl:when test="@type = 'date'">
        <date>
          <!--<xsl:variable name="year" select="if(map:keys($custom) = 'year') then format-number(xs:integer(map:get($custom, 'year')), '0000') else '00'"/>
          <xsl:variable name="month" select=" if(map:keys($custom) = 'month') then format-number(xs:integer(map:get($custom, 'month')), '00') else '00'"/>
          <xsl:variable name="day" select=" if(map:keys($custom) = 'day') then format-number(xs:integer(map:get($custom, 'day')), '00') else '00'"/>
          <xsl:variable name="when" select="$year||'-'||$month||'-'||$day" />
          <xsl:if test="$when != '0000-00-00'">
            <xsl:attribute name="when" select="$when" />
          </xsl:if>-->
          <xsl:for-each select="map:keys($custom)">
            <xsl:if test=". != 'length' and . != ''">
              <xsl:attribute name="{.}" select="map:get($custom, .)" /> 
            </xsl:if>
          </xsl:for-each>
          <xsl:call-template name="elem">
            <xsl:with-param name="elem" select="$elem" />
          </xsl:call-template>
        </date>
      </xsl:when>
      <xsl:when test="@type = 'person'">
        <xsl:variable name="elName" select="if ($rs) then 'rs' else 'persName'" />
        <xsl:element name="{$elName}">
          <xsl:if test="$rs">
            <xsl:attribute name="type">person</xsl:attribute>
          </xsl:if>
          <xsl:if test="$custom('lastname') != '' or $custom('firstname') != ''">
            <xsl:attribute name="key" select="replace($custom('lastname'), '\\u0020', ' ') || ', ' || replace($custom('firstname'), '\\u0020', ' ')" />
          </xsl:if>
          <xsl:if test="$custom('continued')">
            <xsl:attribute name="continued" select="true()" />
          </xsl:if>
          
          <xsl:call-template name="elem">
            <xsl:with-param name="elem" select="$elem" />
          </xsl:call-template>
        </xsl:element>
      </xsl:when>
      <xsl:when test="@type = 'place'">
        <xsl:variable name="elName" select="if ($rs) then 'rs' else 'placeName'" />
        <xsl:element name="{$elName}">
          <xsl:if test="$rs">
            <xsl:attribute name="type">place</xsl:attribute>
          </xsl:if>
          <xsl:if test="$custom('placeName') != ''">
            <xsl:attribute name="key" select="replace($custom('placeName'), '\\u0020', ' ')" />
          </xsl:if>
          
          <xsl:call-template name="elem">
            <xsl:with-param name="elem" select="$elem" />
          </xsl:call-template>
        </xsl:element>
      </xsl:when>
      <xsl:when test="@type = 'organization'">
        <xsl:variable name="elName" select="if ($rs) then 'rs' else 'orgName'" />
        <xsl:element name="{$elName}">
          <xsl:if test="$rs">
            <xsl:attribute name="type">org</xsl:attribute>
          </xsl:if>
          <xsl:call-template name="elem">
            <xsl:with-param name="elem" select="$elem" />
          </xsl:call-template>
        </xsl:element>
      </xsl:when>
      <xsl:otherwise>
        <xsl:element name="{@type}">
          <xsl:call-template name="elem">
            <xsl:with-param name="elem" select="$elem" />
          </xsl:call-template>
        </xsl:element>
      </xsl:otherwise>
    </xsl:choose>
    
    <xsl:apply-templates select="following-sibling::local:m[@pos='e' and @o=$o]/following-sibling::node()[1][self::text()]" />
  </xsl:template>

  <xd:doc>
    <xd:desc>Process what's between a pair of local:m</xd:desc>
    <xd:param name="elem"/>
  </xd:doc>
  <xsl:template name="elem">
    <xsl:param name="elem" />
    
    <xsl:choose>
      <xsl:when test="$elem//local:m">
        <xsl:apply-templates select="$elem/local:t/text()[not(preceding-sibling::local:m)]" />
        <xsl:apply-templates select="$elem/local:t/local:m[@pos='s']
          [not(preceding-sibling::local:m[1][@pos='s'])]" />
      </xsl:when>
      <xsl:otherwise>
        <xsl:sequence select="$elem/local:t/node()" />
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xd:doc>
    <xd:desc>Leave out possibly unwanted parts</xd:desc>
  </xd:doc>
  <xsl:template match="p2017:Metadata | p2019:Metadata" mode="text" />

  <xd:doc>
    <xd:desc>Parse the content of an attribute such as @custom into a map.</xd:desc>
  </xd:doc>
  <xsl:template match="@custom" as="map(*)">
    <xsl:map>
      <xsl:for-each select="tokenize(., '\}')[normalize-space() != '']">
        <xsl:map-entry key="substring-before(normalize-space(), ' ')">
          <xsl:map>
            <xsl:for-each select="tokenize(substring-after(., '{'), ';')[normalize-space() != '']">
              <xsl:map-entry key="substring-before(., ':')" select="substring-after(., ':')" />
            </xsl:for-each>
          </xsl:map>
        </xsl:map-entry>
      </xsl:for-each>
    </xsl:map>
  </xsl:template>

  <xd:doc>
    <xd:desc>Text nodes to be copied</xd:desc>
  </xd:doc>
  <xsl:template match="text()">
    <xsl:value-of select="."/>
  </xsl:template>
</xsl:stylesheet>
