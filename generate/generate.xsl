<?xml version="1.0" encoding="UTF-8"?>
<!--
Transform a service metadata document to a service outline
-->
<xsl:stylesheet version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:exsl="http://exslt.org/common"
  extension-element-prefixes="exsl"
  >

  <xsl:output method="text"/>

  <xsl:param name="output-path" select="'out'" />

  <xsl:variable name="lower" select="'abcdefghijklmnopqrstuvwxyz'" />
  <xsl:variable name="upper" select="'ABCDEFGHIJKLMNOPQRSTUVWXYZ'" />

  <xsl:variable name="namespace-from" select="'./-'" />
  <xsl:variable name="namespace-to"   select="'___'" />

  <xsl:template match="@*|node()" priority="-1">
    <xsl:copy>
      <xsl:apply-templates select="@*|node()"/>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="text()">
    <xsl:if test="normalize-space(.) != ''">
      <xsl:value-of select="."/>
    </xsl:if>
  </xsl:template>

  <!--
    Generate service method for each operation
  -->
  <xsl:template match="*" mode="service">
  public <xsl:value-of select="local-name(.)"/>ResponseType <xsl:value-of select="translate(substring(local-name(.),1,1), $upper, $lower)"/><xsl:value-of select="substring(local-name(.),2)"/>( final <xsl:value-of select="local-name(.)"/>Type request ) {
    return request.getReply( );
  }
  </xsl:template>

  <!--
    Generate api method for each operation
  -->
  <xsl:template match="*" mode="api">
    <xsl:text>
  </xsl:text><xsl:value-of select="local-name(.)"/>ResponseType <xsl:value-of select="translate(substring(local-name(.),1,1), $upper, $lower)"/><xsl:value-of select="substring(local-name(.),2)"/>( final <xsl:value-of select="local-name(.)"/>Type request );<xsl:text>
</xsl:text><xsl:if test="/service-metadata/shapes/*[local-name()=current()/input/@shape and @type='structure' and not(required-collection)]">
  default <xsl:value-of select="local-name(.)"/>ResponseType <xsl:value-of select="translate(substring(local-name(.),1,1), $upper, $lower)"/><xsl:value-of select="substring(local-name(.),2)"/>( ) {
    return <xsl:value-of select="translate(substring(local-name(.),1,1), $upper, $lower)"/><xsl:value-of select="substring(local-name(.),2)"/>( new <xsl:value-of select="local-name(.)"/>Type( ) );
  }
</xsl:if>
  </xsl:template>

  <!--
    Generate async api method for each operation
  -->
  <xsl:template match="*" mode="api-async">
  CheckedListenableFuture&lt;<xsl:value-of select="local-name(.)"/>ResponseType> <xsl:value-of select="translate(substring(local-name(.),1,1), $upper, $lower)"/><xsl:value-of select="substring(local-name(.),2)"/>Async( final <xsl:value-of select="local-name(.)"/>Type request );
<xsl:if test="/service-metadata/shapes/*[local-name()=current()/input/@shape and @type='structure' and not(required-collection)]">
  default CheckedListenableFuture&lt;<xsl:value-of select="local-name(.)"/>ResponseType> <xsl:value-of select="translate(substring(local-name(.),1,1), $upper, $lower)"/><xsl:value-of select="substring(local-name(.),2)"/>Async( ) {
    return <xsl:value-of select="translate(substring(local-name(.),1,1), $upper, $lower)"/><xsl:value-of select="substring(local-name(.),2)"/>Async( new <xsl:value-of select="local-name(.)"/>Type( ) );
  }
</xsl:if>
  </xsl:template>

  <!--
    Map shapes to Java types
  -->
  <xsl:template name="type-mapper">
    <xsl:param name="type"/>
    <xsl:choose>
      <xsl:when test="$type='Binary'">String</xsl:when> <!-- Base64 text -->
      <xsl:when test="$type='BooleanOptional'">Boolean</xsl:when>
      <xsl:when test="$type='DoubleOptional'">Double</xsl:when>
      <xsl:when test="$type='IntegerOptional'">Integer</xsl:when>
      <xsl:when test="$type='LongOptional'">Long</xsl:when>
      <xsl:when test="$type='TStamp'">java.util.Date</xsl:when>
      <xsl:when test="/service-metadata/shapes/*[local-name()=$type and @type='boolean']">Boolean</xsl:when>
      <xsl:when test="/service-metadata/shapes/*[local-name()=$type and @type='double']">Double</xsl:when>
      <xsl:when test="/service-metadata/shapes/*[local-name()=$type and @type='integer']">Integer</xsl:when>
      <xsl:when test="/service-metadata/shapes/*[local-name()=$type and @type='long']">Long</xsl:when>
      <xsl:when test="/service-metadata/shapes/*[local-name()=$type and @type='string']">String</xsl:when>
      <xsl:when test="/service-metadata/shapes/*[local-name()=$type and @type='timestamp']">java.util.Date</xsl:when>
      <xsl:when test="/service-metadata/shapes/*[local-name()=$type and @type='blob']">java.lang.String</xsl:when>
      <xsl:when test="/service-metadata/metadata[@protocol='rest-json' or @protocol='json'] and /service-metadata/shapes/*[local-name()=$type and @type='list']">
        <xsl:text>java.util.ArrayList&lt;</xsl:text>
        <xsl:call-template name="type-mapper"><xsl:with-param name="type" select="/service-metadata/shapes/*[local-name()=$type and @type='list']/member/@shape"/></xsl:call-template>
        <xsl:text>></xsl:text>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$type"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!--
    Map shapes to fully qualified Java types
  -->
  <xsl:template name="qualified-type-mapper">
    <xsl:param name="type"/>
    <xsl:choose>
      <xsl:when test="$type='Binary'">java.lang.String</xsl:when> <!-- Base64 text -->
      <xsl:when test="$type='Boolean'">java.lang.Boolean</xsl:when>
      <xsl:when test="$type='BooleanOptional'">java.lang.Boolean</xsl:when>
      <xsl:when test="$type='Double'">java.lang.Double</xsl:when>
      <xsl:when test="$type='DoubleOptional'">java.lang.Double</xsl:when>
      <xsl:when test="$type='Integer'">java.lang.Integer</xsl:when>
      <xsl:when test="$type='IntegerOptional'">java.lang.Integer</xsl:when>
      <xsl:when test="$type='Long'">java.lang.Long</xsl:when>
      <xsl:when test="$type='LongOptional'">java.lang.Long</xsl:when>
      <xsl:when test="$type='String'">java.lang.String</xsl:when>
      <xsl:when test="$type='TStamp'">java.util.Date</xsl:when>
      <xsl:when test="/service-metadata/shapes/*[local-name()=$type and @type='boolean']">java.lang.Boolean</xsl:when>
      <xsl:when test="/service-metadata/shapes/*[local-name()=$type and @type='double']">java.lang.Double</xsl:when>
      <xsl:when test="/service-metadata/shapes/*[local-name()=$type and @type='integer']">java.lang.Integer</xsl:when>
      <xsl:when test="/service-metadata/shapes/*[local-name()=$type and @type='long']">java.lang.Long</xsl:when>
      <xsl:when test="/service-metadata/shapes/*[local-name()=$type and @type='string']">java.lang.String</xsl:when>
      <xsl:when test="/service-metadata/shapes/*[local-name()=$type and @type='timestamp']">java.util.Date</xsl:when>
      <xsl:when test="/service-metadata/shapes/*[local-name()=$type and @type='blob']">java.lang.String</xsl:when>
      <xsl:when test="/service-metadata/metadata[@protocol='rest-json' or @protocol='json'] and /service-metadata/shapes/*[local-name()=$type and @type='list']">
        <xsl:text>java.util.ArrayList&lt;</xsl:text>
        <xsl:call-template name="type-mapper"><xsl:with-param name="type" select="/service-metadata/shapes/*[local-name()=$type and @type='list']/member/@shape"/></xsl:call-template>
        <xsl:text>></xsl:text>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$type"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!--
    Map shapes @HttpEmbededded if required when type used in ArrayList
  -->
  <xsl:template name="type-httpembedded">
    <xsl:param name="type"/>
    <xsl:choose>
      <xsl:when test="$type='Binary'"></xsl:when>
      <xsl:when test="$type='BooleanOptional'"></xsl:when>
      <xsl:when test="$type='DoubleOptional'"></xsl:when>
      <xsl:when test="$type='IntegerOptional'"></xsl:when>
      <xsl:when test="$type='LongOptional'"></xsl:when>
      <xsl:when test="$type='TStamp'"></xsl:when>
      <xsl:when test="/service-metadata/shapes/*[local-name()=$type and @type='boolean']"></xsl:when>
      <xsl:when test="/service-metadata/shapes/*[local-name()=$type and @type='double']"></xsl:when>
      <xsl:when test="/service-metadata/shapes/*[local-name()=$type and @type='integer']"></xsl:when>
      <xsl:when test="/service-metadata/shapes/*[local-name()=$type and @type='long']"></xsl:when>
      <xsl:when test="/service-metadata/shapes/*[local-name()=$type and @type='string']"></xsl:when>
      <xsl:when test="/service-metadata/shapes/*[local-name()=$type and @type='timestamp']"></xsl:when>
      <xsl:when test="/service-metadata/shapes/*[local-name()=$type and @type='blob']"></xsl:when>
      <xsl:when test="/service-metadata/metadata[@protocol='rest-json' or @protocol='json'] and /service-metadata/shapes/*[local-name()=$type and @type='list']"></xsl:when>
      <xsl:otherwise>
        <xsl:text>@HttpEmbedded(multiple = true)
</xsl:text>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!--
    Generate fields for a shape
  -->
  <xsl:template match="*" mode="shape-fields">
    <xsl:if test="members/*"><xsl:text>
</xsl:text></xsl:if>
    <xsl:for-each select="members/*">
<xsl:if test="../../required-collection/required[@value=local-name(current())]">  @Nonnull
</xsl:if><xsl:if test="@location='header' and @locationName">  @HttpHeaderMapping(header="<xsl:value-of select="@locationName"/>")
</xsl:if><xsl:if test="@location='querystring' and @locationName">  @HttpParameterMapping(parameter="<xsl:value-of select="@locationName"/>")
</xsl:if><xsl:if test="@location='uri' and @locationName">  @HttpUriMapping(uri="<xsl:value-of select="@locationName"/>")
</xsl:if><xsl:if test="/service-metadata/shapes/*[local-name()=current()/@shape and (@min or @max)]">
  <xsl:text>  @FieldRange(</xsl:text>
  <xsl:if test="/service-metadata/shapes/*[local-name()=current()/@shape and @min != 0]"><xsl:text>min=</xsl:text><xsl:value-of select="/service-metadata/shapes/*[local-name()=current()/@shape]/@min"/></xsl:if>
  <xsl:if test="/service-metadata/shapes/*[local-name()=current()/@shape and @min != 0 and @max]"><xsl:text>, </xsl:text></xsl:if>
  <xsl:if test="/service-metadata/shapes/*[local-name()=current()/@shape and @max]">max=<xsl:value-of select="/service-metadata/shapes/*[local-name()=current()/@shape]/@max"/></xsl:if>
  <xsl:text>)
</xsl:text>
</xsl:if><xsl:if test="/service-metadata/shapes/*[local-name()=current()/@shape and @type='string' and enum-collection/enum]">
  <xsl:text>  @FieldRegex(FieldRegexValue.ENUM_</xsl:text><xsl:value-of select="translate(@shape, $lower, $upper)"/><xsl:text>)
</xsl:text>
</xsl:if>  private <xsl:call-template name="type-mapper"><xsl:with-param name="type" select="@shape"/></xsl:call-template><xsl:text> </xsl:text><xsl:value-of select="translate(substring(local-name(.),1,1), $upper, $lower)"/><xsl:value-of select="substring(local-name(.),2)"/><xsl:if test="../../@payload = local-name(.)"> = new <xsl:call-template name="type-mapper"><xsl:with-param name="type" select="@shape"/></xsl:call-template>()</xsl:if>;
</xsl:for-each>
  </xsl:template>

  <!--
    Generate getters/setters for a shape
  -->
  <xsl:template match="*" mode="shape-getters">
    <xsl:for-each select="members/*"><xsl:if test="substring(local-name(.),1,1) != translate(substring(local-name(.),1,1), $lower, $upper)">
  @com.fasterxml.jackson.annotation.JsonProperty("<xsl:value-of select="local-name(.)"/>")</xsl:if>
  public <xsl:call-template name="type-mapper"><xsl:with-param name="type" select="@shape"/></xsl:call-template> get<xsl:value-of select="translate(substring(local-name(.),1,1), $lower, $upper)"/><xsl:value-of select="substring(local-name(.),2)"/>( ) {
    return <xsl:value-of select="translate(substring(local-name(.),1,1), $upper, $lower)"/><xsl:value-of select="substring(local-name(.),2)"/>;
  }

  public void set<xsl:value-of select="translate(substring(local-name(.),1,1), $lower, $upper)"/><xsl:value-of select="substring(local-name(.),2)"/>( final <xsl:call-template name="type-mapper"><xsl:with-param name="type" select="@shape"/></xsl:call-template><xsl:text> </xsl:text><xsl:value-of select="translate(substring(local-name(.),1,1), $upper, $lower)"/><xsl:value-of select="substring(local-name(.),2)"/> ) {
    this.<xsl:value-of select="translate(substring(local-name(.),1,1), $upper, $lower)"/><xsl:value-of select="substring(local-name(.),2)"/> = <xsl:value-of select="translate(substring(local-name(.),1,1), $upper, $lower)"/><xsl:value-of select="substring(local-name(.),2)"/>;
  }
</xsl:for-each>
  </xsl:template>

  <!--
    Generate class for used shapes
  -->
  <xsl:template match="Binary|Boolean|BooleanOptional|Double|DoubleOptional|Integer|IntegerOptional|Long|LongOptional|String|TStamp" mode="shape"/>
  <xsl:template match="*[@type='blob']" mode="shape"/>
  <xsl:template match="*[@type='boolean']" mode="shape"/>
  <xsl:template match="*[@type='double']" mode="shape"/>
  <xsl:template match="*[@type='integer']" mode="shape"/>
  <xsl:template match="*[@type='long']" mode="shape"/>
  <xsl:template match="*[@type='string']" mode="shape"/>
  <xsl:template match="*[@type='timestamp']" mode="shape"/>
  <xsl:template match="*" mode="shape">
    <xsl:variable name="service-lower"><xsl:value-of select="translate(/service-metadata/metadata/@serviceId, $upper, $lower)"/></xsl:variable>
    <xsl:variable name="service-sente"><xsl:choose><xsl:when test="/service-metadata/metadata/@serviceIdCamel"><xsl:value-of select="/service-metadata/metadata/@serviceIdCamel"/></xsl:when><xsl:otherwise><xsl:value-of select="translate(substring(/service-metadata/metadata/@serviceId,1,1), $lower, $upper)"/><xsl:value-of select="translate(substring(/service-metadata/metadata/@serviceId,2), $upper, $lower)"/></xsl:otherwise></xsl:choose></xsl:variable>
    <!-- generated if used by another structure or list shape -->
    <xsl:if test="/service-metadata/shapes/*[@type='structure']/members/*[@shape=local-name(current())] or /service-metadata/shapes/*[@type='list']/member[@shape=local-name(current())] or /service-metadata/shapes/*[@type='map']/*[@shape=local-name(current())]">
      <xsl:choose>
        <xsl:when test="@type='list'">
<xsl:if test="not(/service-metadata/metadata[@protocol='rest-json' or @protocol='json'])">
<exsl:document href="{$output-path}/{$service-lower}-common/src/main/java/com/eucalyptus/{$service-lower}/common/msgs/{local-name(.)}.java" method="text">/*
 * Copyright 2020 AppScale Systems, Inc
 *
 * Use of this source code is governed by a BSD-2-Clause
 * license that can be found in the LICENSE file or at
 * https://opensource.org/licenses/BSD-2-Clause
 */
package com.eucalyptus.<xsl:value-of select="$service-lower"/>.common.msgs;

import com.eucalyptus.binding.HttpEmbedded;
import com.eucalyptus.binding.HttpParameterMapping;
import edu.ucsb.eucalyptus.msgs.EucalyptusData;
import java.util.ArrayList;


public class <xsl:value-of select="local-name(.)"/> extends EucalyptusData {

  <xsl:call-template name="type-httpembedded"><xsl:with-param name="type" select="member/@shape"/></xsl:call-template>@HttpParameterMapping(parameter = "<xsl:value-of select="concat(member/@locationName, substring('member', 1 div not(member/@locationName)))"/>")
  private ArrayList&lt;<xsl:call-template name="type-mapper"><xsl:with-param name="type" select="member/@shape"/></xsl:call-template>> member = new ArrayList&lt;>();

  public ArrayList&lt;<xsl:call-template name="type-mapper"><xsl:with-param name="type" select="member/@shape"/></xsl:call-template>> getMember( ) {
    return member;
  }

  public void setMember( final ArrayList&lt;<xsl:call-template name="type-mapper"><xsl:with-param name="type" select="member/@shape"/></xsl:call-template>> member ) {
    this.member = member;
  }
}
</exsl:document>
</xsl:if>
        </xsl:when>
        <xsl:when test="@type='map'">
<exsl:document href="{$output-path}/{$service-lower}-common/src/main/java/com/eucalyptus/{$service-lower}/common/msgs/{local-name(.)}.java" method="text">/*
 * Copyright 2020 AppScale Systems, Inc
 *
 * Use of this source code is governed by a BSD-2-Clause
 * license that can be found in the LICENSE file or at
 * https://opensource.org/licenses/BSD-2-Clause
 */
package com.eucalyptus.<xsl:value-of select="$service-lower"/>.common.msgs;

import edu.ucsb.eucalyptus.msgs.EucalyptusData;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.Map;

public class <xsl:value-of select="local-name(.)"/> extends EucalyptusData {
<xsl:choose>
<xsl:when test="/service-metadata/metadata[@protocol='rest-json' or @protocol='json']">
  private Map&lt;<xsl:call-template name="qualified-type-mapper"><xsl:with-param name="type" select="key/@shape"/></xsl:call-template>,<xsl:call-template name="qualified-type-mapper"><xsl:with-param name="type" select="value/@shape"/></xsl:call-template>> mapping = new HashMap&lt;>( );

  public Map&lt;<xsl:call-template name="qualified-type-mapper"><xsl:with-param name="type" select="key/@shape"/></xsl:call-template>,<xsl:call-template name="qualified-type-mapper"><xsl:with-param name="type" select="value/@shape"/></xsl:call-template>> getMapping( ) {
    return mapping;
  }

  public void setMapping( final Map&lt;<xsl:call-template name="qualified-type-mapper"><xsl:with-param name="type" select="key/@shape"/></xsl:call-template>,<xsl:call-template name="qualified-type-mapper"><xsl:with-param name="type" select="value/@shape"/></xsl:call-template>> mapping ) {
    this.mapping = mapping;
  }

  public void setMapping( final <xsl:call-template name="qualified-type-mapper"><xsl:with-param name="type" select="key/@shape"/></xsl:call-template> key,
                          final <xsl:call-template name="qualified-type-mapper"><xsl:with-param name="type" select="value/@shape"/></xsl:call-template> value ) {
    mapping.put( key, value );
  }
</xsl:when>
<xsl:otherwise>
  private ArrayList&lt;<xsl:value-of select="local-name(.)"/>Entry> entry = new ArrayList&lt;>();

  public ArrayList&lt;<xsl:value-of select="local-name(.)"/>Entry> getEntry( ) {
    return entry;
  }

  public void setEntry( final ArrayList&lt;<xsl:value-of select="local-name(.)"/>Entry> entry ) {
    this.entry = entry;
  }
</xsl:otherwise>
</xsl:choose>
}
</exsl:document>
<xsl:if test="/service-metadata/metadata[@protocol!='rest-json']">
<exsl:document href="{$output-path}/{$service-lower}-common/src/main/java/com/eucalyptus/{$service-lower}/common/msgs/{local-name(.)}Entry.java" method="text">/*
 * Copyright 2020 AppScale Systems, Inc
 *
 * Use of this source code is governed by a BSD-2-Clause
 * license that can be found in the LICENSE file or at
 * https://opensource.org/licenses/BSD-2-Clause
 */
package com.eucalyptus.<xsl:value-of select="$service-lower"/>.common.msgs;

import edu.ucsb.eucalyptus.msgs.EucalyptusData;
import java.util.ArrayList;


public class <xsl:value-of select="local-name(.)"/>Entry extends EucalyptusData {

  private <xsl:call-template name="qualified-type-mapper"><xsl:with-param name="type" select="key/@shape"/></xsl:call-template> key;
  private <xsl:call-template name="qualified-type-mapper"><xsl:with-param name="type" select="value/@shape"/></xsl:call-template> value;

  public <xsl:call-template name="qualified-type-mapper"><xsl:with-param name="type" select="key/@shape"/></xsl:call-template> getKey( ) {
    return key;
  }

  public void setKey( final <xsl:call-template name="qualified-type-mapper"><xsl:with-param name="type" select="key/@shape"/></xsl:call-template> key ) {
    this.key = key;
  }

  public <xsl:call-template name="qualified-type-mapper"><xsl:with-param name="type" select="value/@shape"/></xsl:call-template> getValue( ) {
    return value;
  }

  public void setValue( final <xsl:call-template name="qualified-type-mapper"><xsl:with-param name="type" select="value/@shape"/></xsl:call-template> value ) {
    this.value = value;
  }
}
</exsl:document>
</xsl:if>
        </xsl:when>
        <xsl:when test="@type='structure'">
<exsl:document href="{$output-path}/{$service-lower}-common/src/main/java/com/eucalyptus/{$service-lower}/common/msgs/{local-name(.)}.java" method="text">/*
 * Copyright 2020 AppScale Systems, Inc
 *
 * Use of this source code is governed by a BSD-2-Clause
 * license that can be found in the LICENSE file or at
 * https://opensource.org/licenses/BSD-2-Clause
 */
package com.eucalyptus.<xsl:value-of select="$service-lower"/>.common.msgs;

import edu.ucsb.eucalyptus.msgs.EucalyptusData;
import javax.annotation.Nonnull;
import com.eucalyptus.<xsl:value-of select="$service-lower"/>.common.<xsl:value-of select="$service-sente"/>MessageValidation.FieldRange;
import com.eucalyptus.<xsl:value-of select="$service-lower"/>.common.<xsl:value-of select="$service-sente"/>MessageValidation.FieldRegex;
import com.eucalyptus.<xsl:value-of select="$service-lower"/>.common.<xsl:value-of select="$service-sente"/>MessageValidation.FieldRegexValue;


public class <xsl:value-of select="local-name(.)"/> extends EucalyptusData {
<xsl:apply-templates select="." mode="shape-fields"/>
<xsl:apply-templates select="." mode="shape-getters"/>
}
</exsl:document>
        </xsl:when>
        <xsl:otherwise>
          <xsl:message terminate="yes">Unknown shape type <xsl:value-of select="@type"/> (add to shape xsl:choose)</xsl:message>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:if>
  </xsl:template>

  <!--
    Generate request/response messages and result holders.
  -->
  <xsl:template match="*" mode="message">
    <xsl:variable name="service-lower"><xsl:value-of select="translate(/service-metadata/metadata/@serviceId, $upper, $lower)"/></xsl:variable>
    <xsl:variable name="service-sente"><xsl:choose><xsl:when test="/service-metadata/metadata/@serviceIdCamel"><xsl:value-of select="/service-metadata/metadata/@serviceIdCamel"/></xsl:when><xsl:otherwise><xsl:value-of select="translate(substring(/service-metadata/metadata/@serviceId,1,1), $lower, $upper)"/><xsl:value-of select="translate(substring(/service-metadata/metadata/@serviceId,2), $upper, $lower)"/></xsl:otherwise></xsl:choose></xsl:variable>
    <exsl:document href="{$output-path}/{$service-lower}-common/src/main/java/com/eucalyptus/{$service-lower}/common/msgs/{local-name(.)}Type.java" method="text">/*
 * Copyright 2020 AppScale Systems, Inc
 *
 * Use of this source code is governed by a BSD-2-Clause
 * license that can be found in the LICENSE file or at
 * https://opensource.org/licenses/BSD-2-Clause
 */
package com.eucalyptus.<xsl:value-of select="$service-lower"/>.common.msgs;

import javax.annotation.Nonnull;
import com.eucalyptus.binding.HttpContent;
import com.eucalyptus.binding.HttpNoContent;
import com.eucalyptus.binding.HttpHeaderMapping;
import com.eucalyptus.binding.HttpParameterMapping;
import com.eucalyptus.binding.HttpRequestMapping;
import com.eucalyptus.binding.HttpUriMapping;
import com.eucalyptus.<xsl:value-of select="$service-lower"/>.common.<xsl:value-of select="$service-sente"/>MessageValidation.FieldRange;
import com.eucalyptus.<xsl:value-of select="$service-lower"/>.common.<xsl:value-of select="$service-sente"/>MessageValidation.FieldRegex;
import com.eucalyptus.<xsl:value-of select="$service-lower"/>.common.<xsl:value-of select="$service-sente"/>MessageValidation.FieldRegexValue;


<xsl:if test="/service-metadata/metadata[@protocol='json' or @protocol='rest-json' or @protocol='rest-xml'] and http/@requestUri">
@HttpRequestMapping(method="<xsl:value-of select="http/@method"/>", uri="<xsl:value-of select="http/@requestUri"/>")</xsl:if>
<xsl:if test="/service-metadata/metadata[@protocol='rest-json' or @protocol='rest-xml'] and (http/@method='GET' or http/@method='DELETE' or not(/service-metadata/shapes/*[local-name()=current()/input/@shape and @type='structure']/members/*))">
@HttpNoContent</xsl:if>
<xsl:if test="/service-metadata/shapes/*[local-name()=current()/input/@shape and @type='structure']/@payload">
@HttpContent(payload="<xsl:value-of select="translate(substring(/service-metadata/shapes/*[local-name()=current()/input/@shape and @type='structure']/@payload,1,1), $upper, $lower)"/><xsl:value-of select="substring(/service-metadata/shapes/*[local-name()=current()/input/@shape and @type='structure']/@payload,2)"/>")</xsl:if>
public class <xsl:value-of select="local-name(.)"/>Type extends <xsl:value-of select="$service-sente"/>Message {
<xsl:if test="input/@shape">
<xsl:apply-templates select="/service-metadata/shapes/*[local-name()=current()/input/@shape and @type='structure']" mode="shape-fields"/>
<xsl:apply-templates select="/service-metadata/shapes/*[local-name()=current()/input/@shape and @type='structure']" mode="shape-getters"/>
</xsl:if>
}
</exsl:document>
    <exsl:document href="{$output-path}/{$service-lower}-common/src/main/java/com/eucalyptus/{$service-lower}/common/msgs/{local-name(.)}ResponseType.java" method="text">/*
 * Copyright 2020 AppScale Systems, Inc
 *
 * Use of this source code is governed by a BSD-2-Clause
 * license that can be found in the LICENSE file or at
 * https://opensource.org/licenses/BSD-2-Clause
 */
package com.eucalyptus.<xsl:value-of select="$service-lower"/>.common.msgs;

import javax.annotation.Nonnull;
import com.eucalyptus.binding.HttpContent;
import com.eucalyptus.binding.HttpHeaderMapping;
import com.eucalyptus.binding.HttpNoContent;
import com.eucalyptus.<xsl:value-of select="$service-lower"/>.common.<xsl:value-of select="$service-sente"/>MessageValidation.FieldRange;
import com.eucalyptus.<xsl:value-of select="$service-lower"/>.common.<xsl:value-of select="$service-sente"/>MessageValidation.FieldRegex;
import com.eucalyptus.<xsl:value-of select="$service-lower"/>.common.<xsl:value-of select="$service-sente"/>MessageValidation.FieldRegexValue;


<xsl:if test="/service-metadata/metadata[@protocol='rest-json' or @protocol='rest-xml'] and not(/service-metadata/shapes/*[local-name()=current()/output/@shape and @type='structure']/members/*)">
@HttpNoContent</xsl:if>
<xsl:if test="/service-metadata/shapes/*[local-name()=current()/output/@shape and @type='structure']/@payload">
@HttpContent(payload="<xsl:value-of select="translate(substring(/service-metadata/shapes/*[local-name()=current()/output/@shape and @type='structure']/@payload,1,1), $upper, $lower)"/><xsl:value-of select="substring(/service-metadata/shapes/*[local-name()=current()/output/@shape and @type='structure']/@payload,2)"/>")</xsl:if>
public class <xsl:value-of select="local-name(.)"/>ResponseType extends <xsl:value-of select="$service-sente"/>Message {

<xsl:choose>
<xsl:when test="output/@resultWrapper">  private <xsl:value-of select="output/@resultWrapper"/> result = new <xsl:value-of select="output/@resultWrapper"/>( );
</xsl:when>
<xsl:otherwise>
<xsl:apply-templates select="/service-metadata/shapes/*[local-name()=current()/output/@shape and @type='structure']" mode="shape-fields"/>
<xsl:apply-templates select="/service-metadata/shapes/*[local-name()=current()/output/@shape and @type='structure']" mode="shape-getters"/>
</xsl:otherwise>
</xsl:choose>
<xsl:if test="/service-metadata/metadata/@protocol = 'query'">  private ResponseMetadata responseMetadata = new ResponseMetadata( );
</xsl:if>
<xsl:if test="output/@resultWrapper">
  public <xsl:value-of select="output/@resultWrapper"/> get<xsl:value-of select="output/@resultWrapper"/>( ) {
    return result;
  }

  public void set<xsl:value-of select="output/@resultWrapper"/>( final <xsl:value-of select="output/@resultWrapper"/> result ) {
    this.result = result;
  }
</xsl:if>
<xsl:if test="/service-metadata/metadata/@protocol = 'query'">  public ResponseMetadata getResponseMetadata( ) {
    return responseMetadata;
  }

  public void setResponseMetadata( final ResponseMetadata responseMetadata ) {
    this.responseMetadata = responseMetadata;
  }
</xsl:if>
}
</exsl:document>
<xsl:if test="output/@resultWrapper">
    <exsl:document href="{$output-path}/{$service-lower}-common/src/main/java/com/eucalyptus/{$service-lower}/common/msgs/{output/@resultWrapper}.java" method="text">/*
 * Copyright 2020 AppScale Systems, Inc
 *
 * Use of this source code is governed by a BSD-2-Clause
 * license that can be found in the LICENSE file or at
 * https://opensource.org/licenses/BSD-2-Clause
 */
package com.eucalyptus.<xsl:value-of select="$service-lower"/>.common.msgs;

import edu.ucsb.eucalyptus.msgs.EucalyptusData;
import com.eucalyptus.<xsl:value-of select="$service-lower"/>.common.<xsl:value-of select="$service-sente"/>MessageValidation.FieldRange;
import com.eucalyptus.<xsl:value-of select="$service-lower"/>.common.<xsl:value-of select="$service-sente"/>MessageValidation.FieldRegex;
import com.eucalyptus.<xsl:value-of select="$service-lower"/>.common.<xsl:value-of select="$service-sente"/>MessageValidation.FieldRegexValue;
import javax.annotation.Nonnull;


public class <xsl:value-of select="output/@resultWrapper"/> extends EucalyptusData {
<xsl:apply-templates select="/service-metadata/shapes/*[local-name()=current()/output/@shape and @type='structure']" mode="shape-fields"/>
<xsl:apply-templates select="/service-metadata/shapes/*[local-name()=current()/output/@shape and @type='structure']" mode="shape-getters"/>
}
</exsl:document>
</xsl:if>
  </xsl:template>

  <!--
    Generate shape binding content
  -->
  <xsl:template match="*" mode="binding-shape-content">
    <xsl:variable name="service-lower"><xsl:value-of select="translate(/service-metadata/metadata/@serviceId, $upper, $lower)"/></xsl:variable>
    <xsl:for-each select="members/*[not(@location)]">
      <xsl:choose>
        <xsl:when test="/service-metadata/shapes/*[(@type='structure' or @type='list' or @type='map') and local-name()=current()/@shape]">
      <structure get-method="get{local-name()}" set-method="set{local-name()}" usage="optional" type="com.eucalyptus.{$service-lower}.common.msgs.{@shape}">
        <xsl:if test="not(/service-metadata/shapes/*[@payload = local-name(current())])">
          <xsl:attribute name="name"><xsl:value-of select="local-name()"/></xsl:attribute>
        </xsl:if>
      </structure>
        </xsl:when>
        <xsl:otherwise>
      <value name="{local-name()}" get-method="get{local-name()}" set-method="set{local-name()}" usage="optional"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:for-each>
  </xsl:template>

  <!--
    Generate shape binding
  -->
  <xsl:template match="Binary|Boolean|BooleanOptional|Double|DoubleOptional|Integer|IntegerOptional|Long|LongOptional|String|TStamp" mode="binding-shape"/>
  <xsl:template match="*[@type='boolean']" mode="binding-shape"/>
  <xsl:template match="*[@type='double']" mode="binding-shape"/>
  <xsl:template match="*[@type='integer']" mode="binding-shape"/>
  <xsl:template match="*[@type='long']" mode="binding-shape"/>
  <xsl:template match="*[@type='string']" mode="binding-shape"/>
  <xsl:template match="*[@type='timestamp']" mode="binding-shape"/>
  <xsl:template match="*" mode="binding-shape">
    <xsl:variable name="service-lower"><xsl:value-of select="translate(/service-metadata/metadata/@serviceId, $upper, $lower)"/></xsl:variable>
    <!-- generated if used by another structure or list shape -->
    <xsl:if test="/service-metadata/shapes/*[@type='structure']/members/*[@shape=local-name(current())] or /service-metadata/shapes/*[@type='list']/member[@shape=local-name(current())] or /service-metadata/shapes/*[@type='map']/*[@shape=local-name(current())]">
      <xsl:choose>
        <xsl:when test="@type='list'">
  <mapping class="com.eucalyptus.{$service-lower}.common.msgs.{local-name(.)}" abstract="true">
    <collection field="member">
      <xsl:choose>
        <xsl:when test="/service-metadata/shapes/*[@type='structure' and local-name()=current()/member/@shape]">
      <structure name="{concat(member/@locationName, substring('member', 1 div not(member/@locationName)))}" type="com.eucalyptus.{$service-lower}.common.msgs.{current()/member/@shape}"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:element name="value">
            <xsl:attribute name="name"><xsl:value-of select="concat(member/@locationName, substring('member', 1 div not(member/@locationName)))"/></xsl:attribute>
            <xsl:attribute name="type"><xsl:call-template name="qualified-type-mapper"><xsl:with-param name="type" select="member/@shape"/></xsl:call-template></xsl:attribute>
          </xsl:element>
        </xsl:otherwise>
      </xsl:choose>
    </collection>
  </mapping>
        </xsl:when>
        <xsl:when test="@type='map'">
  <mapping class="com.eucalyptus.{$service-lower}.common.msgs.{local-name(.)}" abstract="true">
    <collection field="entry">
      <structure name="entry" type="com.eucalyptus.{$service-lower}.common.msgs.{local-name(.)}Entry"/>
    </collection>
  </mapping>
  <mapping class="com.eucalyptus.{$service-lower}.common.msgs.{local-name(.)}Entry" abstract="true">
      <xsl:if test="/service-metadata/metadata/@protocol='rest-xml'">
            <xsl:attribute name="ordered">false</xsl:attribute>
      </xsl:if>
      <xsl:choose>
        <xsl:when test="/service-metadata/shapes/*[@type='structure' and local-name()=current()/key/@shape]">
      <structure name="{concat(key/@locationName, substring('key', 1 div not(key/@locationName)))}" get-method="getKey" set-method="setKey" usage="optional" type="com.eucalyptus.{$service-lower}.common.msgs.{current()/key/@shape}"/>
        </xsl:when>
        <xsl:otherwise>
      <value name="{concat(key/@locationName, substring('key', 1 div not(key/@locationName)))}" get-method="getKey" set-method="setKey" usage="optional"/>
        </xsl:otherwise>
      </xsl:choose>
      <xsl:choose>
        <xsl:when test="/service-metadata/shapes/*[@type='structure' and local-name()=current()/value/@shape]">
      <structure name="{concat(value/@locationName, substring('value', 1 div not(value/@locationName)))}" get-method="getValue" set-method="setValue" usage="optional" type="com.eucalyptus.{$service-lower}.common.msgs.{current()/value/@shape}"/>
        </xsl:when>
        <xsl:otherwise>
      <value name="{concat(value/@locationName, substring('value', 1 div not(value/@locationName)))}" get-method="getValue" set-method="setValue" usage="optional"/>
        </xsl:otherwise>
      </xsl:choose>
  </mapping>
        </xsl:when>
        <xsl:when test="@type='structure'">
  <mapping class="com.eucalyptus.{$service-lower}.common.msgs.{local-name(.)}" abstract="true">
          <xsl:if test="/service-metadata/metadata/@protocol='rest-xml'">
            <xsl:attribute name="ordered">false</xsl:attribute>
          </xsl:if>
          <xsl:if test="/service-metadata/shapes/*[@payload = local-name(current())]">
            <xsl:attribute name="name"><xsl:value-of select="local-name(.)"/></xsl:attribute>
            <xsl:attribute name="abstract">false</xsl:attribute>
          </xsl:if>
          <xsl:apply-templates select="." mode="binding-shape-content"/>
  </mapping>
        </xsl:when>
        <xsl:otherwise>
          <xsl:message terminate="yes">Unknown shape type <xsl:value-of select="@type"/> (add to binding-shape xsl:choose)</xsl:message>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:if>
  </xsl:template>

  <!--
    Generate message index for use with JSON services (so no XML binding for message discovery)
  -->
  <xsl:template match="*" mode="message-index">
    <xsl:variable name="service-lower"><xsl:value-of select="translate(/service-metadata/metadata/@serviceId, $upper, $lower)"/></xsl:variable>
    <xsl:variable name="service-sente"><xsl:choose><xsl:when test="/service-metadata/metadata/@serviceIdCamel"><xsl:value-of select="/service-metadata/metadata/@serviceIdCamel"/></xsl:when><xsl:otherwise><xsl:value-of select="translate(substring(/service-metadata/metadata/@serviceId,1,1), $lower, $upper)"/><xsl:value-of select="translate(substring(/service-metadata/metadata/@serviceId,2), $upper, $lower)"/></xsl:otherwise></xsl:choose></xsl:variable>
<xsl:text>com.eucalyptus.</xsl:text><xsl:value-of select="$service-lower"/>.common.msgs.<xsl:value-of select="local-name(.)"/>Type
<xsl:text>com.eucalyptus.</xsl:text><xsl:value-of select="$service-lower"/>.common.msgs.<xsl:value-of select="local-name(.)"/>ResponseType
</xsl:template>

  <!--
    Generate request/response message and result holder bindings
  -->
  <xsl:template match="*" mode="binding-message">
    <xsl:variable name="service-lower"><xsl:value-of select="translate(/service-metadata/metadata/@serviceId, $upper, $lower)"/></xsl:variable>
    <xsl:variable name="service-sente"><xsl:choose><xsl:when test="/service-metadata/metadata/@serviceIdCamel"><xsl:value-of select="/service-metadata/metadata/@serviceIdCamel"/></xsl:when><xsl:otherwise><xsl:value-of select="translate(substring(/service-metadata/metadata/@serviceId,1,1), $lower, $upper)"/><xsl:value-of select="translate(substring(/service-metadata/metadata/@serviceId,2), $upper, $lower)"/></xsl:otherwise></xsl:choose></xsl:variable>
  <mapping name="{concat(input/@locationName, substring(local-name(.), 1 div not(input/@locationName)))}" class="com.eucalyptus.{$service-lower}.common.msgs.{local-name(.)}Type">
<xsl:if test="/service-metadata/metadata/@protocol='rest-xml'">
  <xsl:attribute name="ordered">false</xsl:attribute>
</xsl:if>
    <structure map-as="com.eucalyptus.{$service-lower}.common.msgs.{$service-sente}Message"/>
<xsl:if test="input/@shape">
    <xsl:apply-templates select="/service-metadata/shapes/*[local-name()=current()/input/@shape and @type='structure']" mode="binding-shape-content"/>
</xsl:if>
  </mapping>
  <mapping name="{local-name(.)}Response" class="com.eucalyptus.{$service-lower}.common.msgs.{local-name(.)}ResponseType">
<xsl:if test="/service-metadata/metadata/@protocol='rest-xml'">
  <xsl:attribute name="ordered">false</xsl:attribute>
</xsl:if>
    <structure map-as="com.eucalyptus.{$service-lower}.common.msgs.{$service-sente}Message"/>
<xsl:choose>
  <xsl:when test="output/@resultWrapper">
    <structure name="{output/@resultWrapper}" field="result" usage="required" type="com.eucalyptus.{$service-lower}.common.msgs.{output/@resultWrapper}"/>
  </xsl:when>
  <xsl:otherwise>
<xsl:apply-templates select="/service-metadata/shapes/*[local-name()=current()/output/@shape and @type='structure']" mode="binding-shape-content"/>
  </xsl:otherwise>
</xsl:choose>
<xsl:if test="/service-metadata/metadata/@protocol = 'query'">
    <structure name="ResponseMetadata" field="responseMetadata" usage="required" type="com.eucalyptus.{$service-lower}.common.msgs.ResponseMetadata"/>
</xsl:if>
  </mapping>
<xsl:if test="output/@resultWrapper">
  <mapping class="com.eucalyptus.{$service-lower}.common.msgs.{output/@resultWrapper}" abstract="true">
<xsl:if test="/service-metadata/metadata/@protocol='rest-xml'">
  <xsl:attribute name="ordered">false</xsl:attribute>
</xsl:if>
<xsl:apply-templates select="/service-metadata/shapes/*[local-name()=current()/output/@shape and @type='structure']" mode="binding-shape-content"/>
  </mapping>
</xsl:if>
  </xsl:template>

  <xsl:template match="/service-metadata">
    <xsl:variable name="service-lower"><xsl:value-of select="translate(metadata/@serviceId, $upper, $lower)"/></xsl:variable>
    <xsl:variable name="service-upper"><xsl:value-of select="translate($service-lower, $lower, $upper)"/></xsl:variable>
    <xsl:variable name="service-sente"><xsl:choose><xsl:when test="metadata/@serviceIdCamel"><xsl:value-of select="metadata/@serviceIdCamel"/></xsl:when><xsl:otherwise><xsl:value-of select="translate(substring(metadata/@serviceId,1,1), $lower, $upper)"/><xsl:value-of select="translate(substring(metadata/@serviceId,2), $upper, $lower)"/></xsl:otherwise></xsl:choose></xsl:variable>
    <xsl:variable name="service-ns"><xsl:value-of select="metadata/@xmlNamespace"/></xsl:variable>
    <xsl:variable name="service-desc"><xsl:choose><xsl:when test="metadata/@serviceAbbreviation"><xsl:value-of select="metadata/@serviceAbbreviation"/></xsl:when><xsl:otherwise><xsl:value-of select="metadata/@serviceId"/></xsl:otherwise></xsl:choose></xsl:variable>
    <xsl:variable name="service-version"><xsl:value-of select="metadata/@apiVersion"/></xsl:variable>

    <!--
      Generate build files for common and service modules
    -->
    <exsl:document href="{$output-path}/{$service-lower}-common/build.xml" method="xml" standalone="yes" indent="yes">
<xsl:comment>
  Copyright 2020 AppScale Systems, Inc

  Use of this source code is governed by a BSD-2-Clause
  license that can be found in the LICENSE file or at
  https://opensource.org/licenses/BSD-2-Clause
</xsl:comment>
<project name="eucalyptus-{$service-lower}-common" basedir=".">
    <import file="../module-inc.xml"/>
</project>
    </exsl:document>
    <exsl:document href="{$output-path}/{$service-lower}/build.xml" method="xml" standalone="yes" indent="yes">
<xsl:comment>
  Copyright 2020 AppScale Systems, Inc

  Use of this source code is governed by a BSD-2-Clause
  license that can be found in the LICENSE file or at
  https://opensource.org/licenses/BSD-2-Clause
</xsl:comment>
<project name="eucalyptus-{$service-lower}" basedir=".">
    <import file="../module-inc.xml"/>
</project>
    </exsl:document>
    <exsl:document href="{$output-path}/{$service-lower}-common/ivy.xml" method="xml" standalone="yes" indent="yes">
<xsl:comment>
  Copyright 2020 AppScale Systems, Inc

  Use of this source code is governed by a BSD-2-Clause
  license that can be found in the LICENSE file or at
  https://opensource.org/licenses/BSD-2-Clause
</xsl:comment>
<ivy-module version="2.0">
    <info organisation="com.eucalyptus" module="eucalyptus-{$service-lower}-common"/>
    <dependencies>
        <dependency name="eucalyptus-configuration" rev="latest.integration"/>
    </dependencies>
</ivy-module>
    </exsl:document>
    <exsl:document href="{$output-path}/{$service-lower}/ivy.xml" method="xml" standalone="yes" indent="yes">
<xsl:comment>
  Copyright 2020 AppScale Systems, Inc

  Use of this source code is governed by a BSD-2-Clause
  license that can be found in the LICENSE file or at
  https://opensource.org/licenses/BSD-2-Clause
</xsl:comment>
<ivy-module version="2.0">
    <info organisation="com.eucalyptus" module="eucalyptus-{$service-lower}"/>
    <dependencies>
        <dependency name="eucalyptus-{$service-lower}-common" rev="latest.integration"/>
        <dependency name="eucalyptus-core" rev="latest.integration"/>
    </dependencies>
</ivy-module>
    </exsl:document>

    <!--
      Generate xml message binding or index
    -->
    <xsl:if test="/service-metadata/metadata[@protocol='json' or @protocol='rest-json']">
    <exsl:document href="{$output-path}/{$service-lower}-common/src/main/resources/{$service-lower}-messages.index" method="text">
      <xsl:apply-templates mode="message-index" select="operations/*"/>
    </exsl:document>
    </xsl:if>
    <xsl:if test="/service-metadata/metadata[@protocol='query' or @protocol='rest-xml']">
    <exsl:document href="{$output-path}/{$service-lower}-common/src/main/resources/{$service-lower}-binding.xml" method="xml" standalone="yes" indent="yes">
<xsl:comment>
  Copyright 2020 AppScale Systems, Inc

  Use of this source code is governed by a BSD-2-Clause
  license that can be found in the LICENSE file or at
  https://opensource.org/licenses/BSD-2-Clause
</xsl:comment>
<binding name="{translate(substring-after(substring($service-ns,1,string-length($service-ns)-1),'://'),$namespace-from,$namespace-to)}" force-classes="true" add-constructors="true">
  <namespace uri="{$service-ns}" default="elements" />
  <format
        type="java.util.Date"
        deserializer="org.jibx.runtime.Utility.deserializeDateTime"
        serializer="com.eucalyptus.ws.util.SerializationUtils.serializeDateTime"/>
<xsl:if test="/service-metadata/metadata/@protocol = 'query'">
  <mapping class="com.eucalyptus.{$service-lower}.common.msgs.ResponseMetadata" abstract="true">
    <value name="RequestId" field="requestId" usage="required"/>
  </mapping>
</xsl:if>
  <mapping class="com.eucalyptus.{$service-lower}.common.msgs.Error" abstract="true">
    <value name="Type" field="type" usage="required"/>
    <value name="Code" field="code" usage="required"/>
    <value name="Message" field="message" usage="required"/>
    <structure name="Detail" field="detail" usage="optional" type="com.eucalyptus.{$service-lower}.common.msgs.ErrorDetail"/>
  </mapping>
  <mapping class="com.eucalyptus.{$service-lower}.common.msgs.ErrorDetail" abstract="true"/>
  <mapping name="ErrorResponse" class="com.eucalyptus.{$service-lower}.common.msgs.ErrorResponse">
    <structure map-as="com.eucalyptus.{$service-lower}.common.msgs.{$service-sente}Message"/>
    <collection field="error">
      <structure name="Error" type="com.eucalyptus.{$service-lower}.common.msgs.Error"/>
    </collection>
    <value name="RequestId" field="requestId" usage="required"/>
  </mapping>
  <mapping class="com.eucalyptus.{$service-lower}.common.msgs.{$service-sente}Message" abstract="true"/>
  <xsl:apply-templates mode="binding-message" select="operations/*"/>
  <xsl:apply-templates mode="binding-shape" select="shapes/*"/>
</binding>
    </exsl:document>
    </xsl:if>

    <!--
      Generate component context xml for message endpoint
    -->
    <exsl:document href="{$output-path}/{$service-lower}/src/main/resources/{$service-lower}-component-context.xml" method="xml" standalone="yes" indent="yes">
<xsl:comment>
  Copyright 2020 AppScale Systems, Inc

  Use of this source code is governed by a BSD-2-Clause
  license that can be found in the LICENSE file or at
  https://opensource.org/licenses/BSD-2-Clause
</xsl:comment>
<beans
	xmlns="http://www.springframework.org/schema/beans"
	xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
	xmlns:int="http://www.springframework.org/schema/integration"
	xsi:schemaLocation="
		http://www.springframework.org/schema/beans http://www.springframework.org/schema/beans/spring-beans.xsd
		http://www.springframework.org/schema/integration http://www.springframework.org/schema/integration/spring-integration.xsd"
>

  <int:channel id="{$service-lower}-error"/>

  <int:chain id="{$service-lower}-request-chain" input-channel="{$service-lower}-request">
	<int:header-enricher>
	  <int:error-channel ref="{$service-lower}-error"/>
	</int:header-enricher>
	<int:service-activator ref="{$service-lower}Service">
	  <int:request-handler-advice-chain>
		<ref bean="{$service-lower}MessageValidator"/>
	  </int:request-handler-advice-chain>
	</int:service-activator>
  </int:chain>

  <int:service-activator input-channel="{$service-lower}-error" ref="{$service-lower}ErrorHandler"/>

</beans>
    </exsl:document>

    <!--
      Generate common module code
    -->
    <exsl:document href="{$output-path}/{$service-lower}-common/src/main/java/com/eucalyptus/{$service-lower}/common/{$service-sente}.java" method="text">/*
 * Copyright 2020 AppScale Systems, Inc
 *
 * Use of this source code is governed by a BSD-2-Clause
 * license that can be found in the LICENSE file or at
 * https://opensource.org/licenses/BSD-2-Clause
 */
package com.eucalyptus.<xsl:value-of select="$service-lower"/>.common;

import com.eucalyptus.component.ComponentId;
import com.eucalyptus.component.annotation.AwsServiceName;
import com.eucalyptus.component.annotation.Description;
import com.eucalyptus.component.annotation.Partition;
import com.eucalyptus.auth.policy.annotation.PolicyVendor;
import com.eucalyptus.component.annotation.PublicService;

/**
 *
 */
@PublicService
@AwsServiceName( "<xsl:value-of select="/service-metadata/metadata/@endpointPrefix"/>" )
@PolicyVendor( "<xsl:value-of select="/service-metadata/metadata/@endpointPrefix"/>" )
@Partition( value = <xsl:value-of select="$service-sente"/>.class, manyToOne = true )
@Description( "<xsl:value-of select="$service-desc"/> API service" )
public class <xsl:value-of select="$service-sente"/> extends ComponentId {
  private static final long serialVersionUID = 1L;
}
</exsl:document>
    <exsl:document href="{$output-path}/{$service-lower}-common/src/main/java/com/eucalyptus/{$service-lower}/common/{$service-sente}Metadata.java" method="text">/*
 * Copyright 2020 AppScale Systems, Inc
 *
 * Use of this source code is governed by a BSD-2-Clause
 * license that can be found in the LICENSE file or at
 * https://opensource.org/licenses/BSD-2-Clause
 */
package com.eucalyptus.<xsl:value-of select="$service-lower"/>.common;

import com.eucalyptus.auth.policy.annotation.PolicyResourceType;
import com.eucalyptus.auth.policy.annotation.PolicyVendor;
import com.eucalyptus.auth.type.RestrictedType;
import com.eucalyptus.<xsl:value-of select="$service-lower"/>.common.policy.<xsl:value-of select="$service-sente"/>PolicySpec;

@PolicyVendor( <xsl:value-of select="$service-sente"/>PolicySpec.VENDOR_<xsl:value-of select="$service-upper"/> )
public interface <xsl:value-of select="$service-sente"/>Metadata extends RestrictedType {

  //TODO add policy resource types
  //@PolicyResourceType( "lower_case_name-here" )
  //interface XXXMetadata extends <xsl:value-of select="$service-sente"/>Metadata {}

}
</exsl:document>
    <exsl:document href="{$output-path}/{$service-lower}-common/src/main/java/com/eucalyptus/{$service-lower}/common/{$service-sente}Metadatas.java" method="text">/*
 * Copyright 2020 AppScale Systems, Inc
 *
 * Use of this source code is governed by a BSD-2-Clause
 * license that can be found in the LICENSE file or at
 * https://opensource.org/licenses/BSD-2-Clause
 */
package com.eucalyptus.<xsl:value-of select="$service-lower"/>.common;

import com.eucalyptus.util.RestrictedTypes;


public class <xsl:value-of select="$service-sente"/>Metadatas extends RestrictedTypes {
}
</exsl:document>
    <exsl:document href="{$output-path}/{$service-lower}-common/src/main/java/com/eucalyptus/{$service-lower}/common/{$service-sente}Api.java" method="text">/*
 * Copyright 2020 AppScale Systems, Inc
 *
 * Use of this source code is governed by a BSD-2-Clause
 * license that can be found in the LICENSE file or at
 * https://opensource.org/licenses/BSD-2-Clause
 */
package com.eucalyptus.<xsl:value-of select="$service-lower"/>.common;

import com.eucalyptus.component.annotation.ComponentPart;
import com.eucalyptus.<xsl:value-of select="$service-lower"/>.common.msgs.*;


@ComponentPart(<xsl:value-of select="$service-sente"/>.class)
public interface <xsl:value-of select="$service-sente"/>Api {
<xsl:apply-templates mode="api" select="operations/*"/>
}
</exsl:document>
    <exsl:document href="{$output-path}/{$service-lower}-common/src/main/java/com/eucalyptus/{$service-lower}/common/{$service-sente}ApiAsync.java" method="text">/*
 * Copyright 2020 AppScale Systems, Inc
 *
 * Use of this source code is governed by a BSD-2-Clause
 * license that can be found in the LICENSE file or at
 * https://opensource.org/licenses/BSD-2-Clause
 */
package com.eucalyptus.<xsl:value-of select="$service-lower"/>.common;

import com.eucalyptus.component.annotation.ComponentPart;
import com.eucalyptus.<xsl:value-of select="$service-lower"/>.common.msgs.*;
import com.eucalyptus.util.async.CheckedListenableFuture;


@ComponentPart(<xsl:value-of select="$service-sente"/>.class)
public interface <xsl:value-of select="$service-sente"/>ApiAsync {
<xsl:apply-templates mode="api-async" select="operations/*"/>
}
</exsl:document>
<exsl:document href="{$output-path}/{$service-lower}-common/src/main/java/com/eucalyptus/{$service-lower}/common/{$service-sente}MessageValidation.java" method="text">/*
 * Copyright 2020 AppScale Systems, Inc
 *
 * Use of this source code is governed by a BSD-2-Clause
 * license that can be found in the LICENSE file or at
 * https://opensource.org/licenses/BSD-2-Clause
 */
package com.eucalyptus.<xsl:value-of select="$service-lower"/>.common;

import java.lang.annotation.ElementType;
import java.lang.annotation.Retention;
import java.lang.annotation.RetentionPolicy;
import java.lang.annotation.Target;
import java.util.regex.Pattern;
import com.eucalyptus.system.Ats;
import com.eucalyptus.util.MessageValidation;
import com.eucalyptus.util.Pair;
import edu.ucsb.eucalyptus.msgs.EucalyptusData;

/**
 *
 */
public class <xsl:value-of select="$service-sente"/>MessageValidation {

  public static class <xsl:value-of select="$service-sente"/>MessageValidationAssistant implements MessageValidation.ValidationAssistant {
    @Override
    public boolean validate( final Object object ) {
      return object instanceof EucalyptusData;
    }

    @Override
    public Pair&lt;Long, Long> range( final Ats ats ) {
      final FieldRange range = ats.get( FieldRange.class );
      return range == null ?
          null :
          Pair.pair( range.min( ), range.max( ) );
    }

    @Override
    public Pattern regex( final Ats ats ) {
      final FieldRegex regex = ats.get( FieldRegex.class );
      return regex == null ?
          null :
          regex.value( ).pattern( );
    }
  }

  @Target( ElementType.FIELD)
  @Retention( RetentionPolicy.RUNTIME)
  public @interface FieldRegex {
    FieldRegexValue value();
  }

  @Target(ElementType.FIELD)
  @Retention(RetentionPolicy.RUNTIME)
  public @interface FieldRange {
    long min() default 0;
    long max() default Long.MAX_VALUE;
  }

  public enum FieldRegexValue {
    // Generic
    STRING_128( "(?s).{1,128}" ),
    STRING_256( "(?s).{1,256}" ),
<xsl:if test="/service-metadata/shapes/*[@type='string' and enum-collection/enum]">
    // Enums
<xsl:for-each select="/service-metadata/shapes/*[@type='string' and enum-collection/enum]">
      <xsl:text>    ENUM_</xsl:text>
      <xsl:value-of select="translate(local-name(), $lower, $upper)"/>
      <xsl:text>("</xsl:text>
      <xsl:for-each select="enum-collection/enum">
        <xsl:value-of select="@value"/>
        <xsl:if test="position() != last()">
          <xsl:text>|</xsl:text>
        </xsl:if>
      </xsl:for-each>
      <xsl:text>"),
</xsl:text></xsl:for-each></xsl:if>    ;

    private final Pattern pattern;

    private FieldRegexValue( final String regex ) {
      this.pattern = Pattern.compile( regex );
    }

    public Pattern pattern() {
      return pattern;
    }
  }
}
</exsl:document>
    <exsl:document href="{$output-path}/{$service-lower}-common/src/main/java/com/eucalyptus/{$service-lower}/common/msgs/{$service-sente}Message.java" method="text">/*
 * Copyright 2020 AppScale Systems, Inc
 *
 * Use of this source code is governed by a BSD-2-Clause
 * license that can be found in the LICENSE file or at
 * https://opensource.org/licenses/BSD-2-Clause
 */
package com.eucalyptus.<xsl:value-of select="$service-lower"/>.common.msgs;

import java.lang.reflect.Method;
import java.util.Map;
import com.eucalyptus.<xsl:value-of select="$service-lower"/>.common.<xsl:value-of select="$service-sente"/>;
import com.eucalyptus.<xsl:value-of select="$service-lower"/>.common.<xsl:value-of select="$service-sente"/>MessageValidation;
import com.eucalyptus.component.annotation.ComponentMessage;
import com.eucalyptus.util.MessageValidation;
import com.google.common.collect.Maps;
import edu.ucsb.eucalyptus.msgs.BaseMessage;

@ComponentMessage( <xsl:value-of select="$service-sente"/>.class )
public class <xsl:value-of select="$service-sente"/>Message extends BaseMessage {

<xsl:if test="/service-metadata/metadata/@protocol = 'query'">
  @Override
  public &lt;TYPE extends BaseMessage> TYPE getReply( ) {
    TYPE type = super.getReply( );
    final ResponseMetadata responseMetadata = getResponseMetadata( type );
    if ( responseMetadata != null ) {
      responseMetadata.setRequestId( type.getCorrelationId( ) );
    }
    return type;
  }

  public static ResponseMetadata getResponseMetadata( final BaseMessage message ) {
    try {
      Method responseMetadataMethod = message.getClass( ).getMethod( "getResponseMetadata" );
      return ( (ResponseMetadata) responseMetadataMethod.invoke( message ) );
    } catch ( Exception e ) {
    }

    return null;
  }
</xsl:if>

  public Map&lt;String, String> validate( ) {
    return MessageValidation.validateRecursively( Maps.newTreeMap( ), new <xsl:value-of select="$service-sente"/>MessageValidation.<xsl:value-of select="$service-sente"/>MessageValidationAssistant( ), "", this );
  }
}
</exsl:document>
    <exsl:document href="{$output-path}/{$service-lower}-common/src/main/java/com/eucalyptus/{$service-lower}/common/msgs/Error.java" method="text">/*
 * Copyright 2020 AppScale Systems, Inc
 *
 * Use of this source code is governed by a BSD-2-Clause
 * license that can be found in the LICENSE file or at
 * https://opensource.org/licenses/BSD-2-Clause
 */
package com.eucalyptus.<xsl:value-of select="$service-lower"/>.common.msgs;

import edu.ucsb.eucalyptus.msgs.EucalyptusData;

public class Error extends EucalyptusData {

  private String type;
  private String code;
  private String message;
  private ErrorDetail detail;

  public String getType( ) {
    return type;
  }

  public void setType( String type ) {
    this.type = type;
  }

  public String getCode( ) {
    return code;
  }

  public void setCode( String code ) {
    this.code = code;
  }

  public String getMessage( ) {
    return message;
  }

  public void setMessage( String message ) {
    this.message = message;
  }

  public ErrorDetail getDetail( ) {
    return detail;
  }

  public void setDetail( ErrorDetail detail ) {
    this.detail = detail;
  }
}
</exsl:document>
    <exsl:document href="{$output-path}/{$service-lower}-common/src/main/java/com/eucalyptus/{$service-lower}/common/msgs/ErrorDetail.java" method="text">/*
 * Copyright 2020 AppScale Systems, Inc
 *
 * Use of this source code is governed by a BSD-2-Clause
 * license that can be found in the LICENSE file or at
 * https://opensource.org/licenses/BSD-2-Clause
 */
package com.eucalyptus.<xsl:value-of select="$service-lower"/>.common.msgs;

import edu.ucsb.eucalyptus.msgs.EucalyptusData;

public class ErrorDetail extends EucalyptusData {

}
</exsl:document>
    <exsl:document href="{$output-path}/{$service-lower}-common/src/main/java/com/eucalyptus/{$service-lower}/common/msgs/ErrorResponse.java" method="text">/*
 * Copyright 2020 AppScale Systems, Inc
 *
 * Use of this source code is governed by a BSD-2-Clause
 * license that can be found in the LICENSE file or at
 * https://opensource.org/licenses/BSD-2-Clause
 */
package com.eucalyptus.<xsl:value-of select="$service-lower"/>.common.msgs;

import java.util.ArrayList;
import com.eucalyptus.ws.WebServiceError;

public class ErrorResponse extends <xsl:value-of select="$service-sente"/>Message implements WebServiceError {

  private String requestId;
  private ArrayList&lt;Error> error = new ArrayList&lt;Error>( );

  public ErrorResponse( ) {
    set_return( false );
  }

  @Override
  public String toSimpleString( ) {
    final Error at = error.get( 0 );
    return ( at == null ? null : at.getType( ) ) + " error (" + getWebServiceErrorCode( ) + "): " + getWebServiceErrorMessage( );
  }

  @Override
  public String getWebServiceErrorCode( ) {
    final Error at = error.get( 0 );
    return ( at == null ? null : at.getCode( ) );
  }

  @Override
  public String getWebServiceErrorMessage( ) {
    final Error at = error.get( 0 );
    return ( at == null ? null : at.getMessage( ) );
  }

  public String getRequestId( ) {
    return requestId;
  }

  public void setRequestId( String requestId ) {
    this.requestId = requestId;
  }

  public ArrayList&lt;Error> getError( ) {
    return error;
  }

  public void setError( ArrayList&lt;Error> error ) {
    this.error = error;
  }
}
</exsl:document>
<xsl:if test="/service-metadata/metadata/@protocol = 'query'">
    <exsl:document href="{$output-path}/{$service-lower}-common/src/main/java/com/eucalyptus/{$service-lower}/common/msgs/ResponseMetadata.java" method="text">/*
 * Copyright 2020 AppScale Systems, Inc
 *
 * Use of this source code is governed by a BSD-2-Clause
 * license that can be found in the LICENSE file or at
 * https://opensource.org/licenses/BSD-2-Clause
 */
package com.eucalyptus.<xsl:value-of select="$service-lower"/>.common.msgs;

import edu.ucsb.eucalyptus.msgs.EucalyptusData;

public class ResponseMetadata extends EucalyptusData {

  private String requestId;

  public String getRequestId( ) {
    return requestId;
  }

  public void setRequestId( String requestId ) {
    this.requestId = requestId;
  }
}
</exsl:document>
</xsl:if>
    <exsl:document href="{$output-path}/{$service-lower}-common/src/main/java/com/eucalyptus/{$service-lower}/common/policy/{$service-sente}PolicySpec.java" method="text">/*
 * Copyright 2020 AppScale Systems, Inc
 *
 * Use of this source code is governed by a BSD-2-Clause
 * license that can be found in the LICENSE file or at
 * https://opensource.org/licenses/BSD-2-Clause
 */
package com.eucalyptus.<xsl:value-of select="$service-lower"/>.common.policy;

/**
 *
 */
public interface <xsl:value-of select="$service-sente"/>PolicySpec {

  // Vendor
  String VENDOR_<xsl:value-of select="$service-upper"/> = "<xsl:value-of select="/service-metadata/metadata/@endpointPrefix"/>";

  // Actions<xsl:for-each select="/service-metadata/operations/*">
  String <xsl:value-of select="$service-upper"/>_<xsl:value-of select="translate(local-name(), $lower, $upper)"/> = "<xsl:value-of select="translate(local-name(), $upper, $lower)"/>";</xsl:for-each>

}
</exsl:document>
    <xsl:apply-templates mode="message" select="operations/*"/>
    <xsl:apply-templates mode="shape" select="shapes/*"/>

    <!--
      Generate service skeleton code
    -->
    <exsl:document href="{$output-path}/{$service-lower}/src/main/java/com/eucalyptus/{$service-lower}/service/{$service-sente}Exception.java" method="text">/*
 * Copyright 2020 AppScale Systems, Inc
 *
 * Use of this source code is governed by a BSD-2-Clause
 * license that can be found in the LICENSE file or at
 * https://opensource.org/licenses/BSD-2-Clause
 */
package com.eucalyptus.<xsl:value-of select="$service-lower"/>.service;

import com.eucalyptus.ws.EucalyptusWebServiceException;
import com.eucalyptus.ws.Role;

/**
 *
 */
public class <xsl:value-of select="$service-sente"/>Exception extends EucalyptusWebServiceException {
  private static final long serialVersionUID = 1L;

  public <xsl:value-of select="$service-sente"/>Exception(
      final String code,
      final Role role,
      final String message ) {
    super( code, role, message );
  }
}
</exsl:document>
    <exsl:document href="{$output-path}/{$service-lower}/src/main/java/com/eucalyptus/{$service-lower}/service/{$service-sente}ClientException.java" method="text">/*
 * Copyright 2020 AppScale Systems, Inc
 *
 * Use of this source code is governed by a BSD-2-Clause
 * license that can be found in the LICENSE file or at
 * https://opensource.org/licenses/BSD-2-Clause
 */
package com.eucalyptus.<xsl:value-of select="$service-lower"/>.service;

import com.eucalyptus.ws.Role;
import com.eucalyptus.ws.protocol.QueryBindingInfo;

/**
 *
 */
@QueryBindingInfo( statusCode = 400 )
public class <xsl:value-of select="$service-sente"/>ClientException extends <xsl:value-of select="$service-sente"/>Exception {
  private static final long serialVersionUID = 1L;

  public <xsl:value-of select="$service-sente"/>ClientException( final String code, final String message ) {
    super( code, Role.Sender, message );
  }
}
</exsl:document>
    <exsl:document href="{$output-path}/{$service-lower}/src/main/java/com/eucalyptus/{$service-lower}/service/{$service-sente}ServiceException.java" method="text">/*
 * Copyright 2020 AppScale Systems, Inc
 *
 * Use of this source code is governed by a BSD-2-Clause
 * license that can be found in the LICENSE file or at
 * https://opensource.org/licenses/BSD-2-Clause
 */
package com.eucalyptus.<xsl:value-of select="$service-lower"/>.service;

import com.eucalyptus.ws.Role;
import com.eucalyptus.ws.protocol.QueryBindingInfo;

/**
 *
 */
@QueryBindingInfo( statusCode = 500 )
public class <xsl:value-of select="$service-sente"/>ServiceException extends <xsl:value-of select="$service-sente"/>Exception {

  private static final long serialVersionUID = 1L;

  public <xsl:value-of select="$service-sente"/>ServiceException( final String code, final String message ) {
    super( code, Role.Receiver, message );
  }
}
</exsl:document>
    <exsl:document href="{$output-path}/{$service-lower}/src/main/java/com/eucalyptus/{$service-lower}/service/{$service-sente}Service.java" method="text">/*
 * Copyright 2020 AppScale Systems, Inc
 *
 * Use of this source code is governed by a BSD-2-Clause
 * license that can be found in the LICENSE file or at
 * https://opensource.org/licenses/BSD-2-Clause
 */
package com.eucalyptus.<xsl:value-of select="$service-lower"/>.service;

import com.eucalyptus.component.annotation.ComponentNamed;
import com.eucalyptus.<xsl:value-of select="$service-lower"/>.common.msgs.*;

/**
 *
 */
@ComponentNamed
public class <xsl:value-of select="$service-sente"/>Service {
<xsl:apply-templates mode="service" select="operations/*"/>
}
</exsl:document>
    <exsl:document href="{$output-path}/{$service-lower}/src/main/java/com/eucalyptus/{$service-lower}/service/config/{$service-sente}Configuration.java" method="text">/*
 * Copyright 2020 AppScale Systems, Inc
 *
 * Use of this source code is governed by a BSD-2-Clause
 * license that can be found in the LICENSE file or at
 * https://opensource.org/licenses/BSD-2-Clause
 */
package com.eucalyptus.<xsl:value-of select="$service-lower"/>.service.config;

import java.io.Serializable;
import javax.persistence.Entity;
import javax.persistence.PersistenceContext;
import com.eucalyptus.component.annotation.ComponentPart;
import com.eucalyptus.config.ComponentConfiguration;
import com.eucalyptus.<xsl:value-of select="$service-lower"/>.common.<xsl:value-of select="$service-sente"/>;

/**
 *
 */
@Entity
@PersistenceContext( name="eucalyptus_config" )
@ComponentPart( <xsl:value-of select="$service-sente"/>.class )
public class <xsl:value-of select="$service-sente"/>Configuration extends ComponentConfiguration implements Serializable {
  private static final long serialVersionUID = 1L;

  public static final String SERVICE_PATH= "/services/<xsl:value-of select="$service-sente"/>";

  public <xsl:value-of select="$service-sente"/>Configuration() { }

  public <xsl:value-of select="$service-sente"/>Configuration( String partition, String name, String hostName, Integer port ) {
    super( partition, name, hostName, port, SERVICE_PATH );
  }
}
</exsl:document>
    <exsl:document href="{$output-path}/{$service-lower}/src/main/java/com/eucalyptus/{$service-lower}/service/config/{$service-sente}ServiceBuilder.java" method="text">/*
 * Copyright 2020 AppScale Systems, Inc
 *
 * Use of this source code is governed by a BSD-2-Clause
 * license that can be found in the LICENSE file or at
 * https://opensource.org/licenses/BSD-2-Clause
 */
package com.eucalyptus.<xsl:value-of select="$service-lower"/>.service.config;

import org.apache.log4j.Logger;
import com.eucalyptus.component.AbstractServiceBuilder;
import com.eucalyptus.component.ComponentId;
import com.eucalyptus.component.ComponentIds;
import com.eucalyptus.component.annotation.ComponentPart;
import com.eucalyptus.<xsl:value-of select="$service-lower"/>.common.<xsl:value-of select="$service-sente"/>;

/**
 *
 */
@ComponentPart( <xsl:value-of select="$service-sente"/>.class )
public class <xsl:value-of select="$service-sente"/>ServiceBuilder extends AbstractServiceBuilder&lt;<xsl:value-of select="$service-sente"/>Configuration> {
  private static final Logger LOG = Logger.getLogger( <xsl:value-of select="$service-sente"/>ServiceBuilder.class );

  @Override
  public <xsl:value-of select="$service-sente"/>Configuration newInstance( ) {
    return new <xsl:value-of select="$service-sente"/>Configuration( );
  }

  @Override
  public <xsl:value-of select="$service-sente"/>Configuration newInstance( String partition, String name, String host, Integer port ) {
    return new <xsl:value-of select="$service-sente"/>Configuration( partition, name, host, port );
  }

  @Override
  public ComponentId getComponentId( ) {
    return ComponentIds.lookup( <xsl:value-of select="$service-sente"/>.class );
  }
}
</exsl:document>
    <exsl:document href="{$output-path}/{$service-lower}/src/main/java/com/eucalyptus/{$service-lower}/service/ws/{$service-sente}ErrorHandler.java" method="text">/*
 * Copyright 2020 AppScale Systems, Inc
 *
 * Use of this source code is governed by a BSD-2-Clause
 * license that can be found in the LICENSE file or at
 * https://opensource.org/licenses/BSD-2-Clause
 */
package com.eucalyptus.<xsl:value-of select="$service-lower"/>.service.ws;

import org.apache.log4j.Logger;
import com.eucalyptus.<xsl:value-of select="$service-lower"/>.common.msgs.ErrorResponse;
import com.eucalyptus.component.annotation.ComponentNamed;
import com.eucalyptus.ws.Role;
import com.eucalyptus.ws.util.ErrorHandlerSupport;
import edu.ucsb.eucalyptus.msgs.BaseMessage;

/**
 *
 */
@ComponentNamed
public class <xsl:value-of select="$service-sente"/>ErrorHandler extends ErrorHandlerSupport {
  private static final Logger LOG = Logger.getLogger( <xsl:value-of select="$service-sente"/>ErrorHandler.class );
  private static final String INTERNAL_FAILURE = "InternalFailure";

  public <xsl:value-of select="$service-sente"/>ErrorHandler() {<xsl:choose>
  <xsl:when test="/service-metadata/metadata/@protocol='query'">
    super( LOG, <xsl:value-of select="$service-sente"/>QueryBinding.DEFAULT_NAMESPACE, INTERNAL_FAILURE );</xsl:when>
  <xsl:when test="/service-metadata/metadata[@protocol='json' or @protocol='rest-json']">
    super( LOG, "", INTERNAL_FAILURE );</xsl:when>
  <xsl:when test="/service-metadata/metadata/@protocol='rest-xml'">
    super( LOG, <xsl:value-of select="$service-sente"/>RestXmlBinding.DEFAULT_NAMESPACE, INTERNAL_FAILURE );</xsl:when>
  <xsl:otherwise>
    <xsl:message terminate="yes">Unknown protocol type <xsl:value-of select="/service-metadata/metadata/@protocol"/> (add to ErrorHandler choice)</xsl:message>
  </xsl:otherwise>
</xsl:choose>
  }

  @Override
  protected BaseMessage buildErrorResponse( final String correlationId,
                                            final Role role,
                                            final String code,
                                            final String message ) {
    final ErrorResponse errorResp = new ErrorResponse( );
    errorResp.setCorrelationId( correlationId );
    errorResp.setRequestId( correlationId );
    final com.eucalyptus.<xsl:value-of select="$service-lower"/>.common.msgs.Error error = new com.eucalyptus.<xsl:value-of select="$service-lower"/>.common.msgs.Error( );
    error.setType( role == Role.Receiver ? "Receiver" : "Sender" );
    error.setCode( code );
    error.setMessage( message );
    errorResp.getError().add( error );
    return errorResp;
  }
}
</exsl:document>
    <exsl:document href="{$output-path}/{$service-lower}/src/main/java/com/eucalyptus/{$service-lower}/service/ws/{$service-sente}MessageValidator.java" method="text">/*
 * Copyright 2020 AppScale Systems, Inc
 *
 * Use of this source code is governed by a BSD-2-Clause
 * license that can be found in the LICENSE file or at
 * https://opensource.org/licenses/BSD-2-Clause
 */
package com.eucalyptus.<xsl:value-of select="$service-lower"/>.service.ws;

import java.util.Map;
import javax.annotation.Nonnull;

import com.eucalyptus.component.annotation.ComponentNamed;
import com.eucalyptus.context.ServiceAdvice;
import com.eucalyptus.<xsl:value-of select="$service-lower"/>.common.msgs.<xsl:value-of select="$service-sente"/>Message;
import com.eucalyptus.<xsl:value-of select="$service-lower"/>.service.<xsl:value-of select="$service-sente"/>Exception;
import com.eucalyptus.<xsl:value-of select="$service-lower"/>.service.<xsl:value-of select="$service-sente"/>ClientException;

/**
 *
 */
@ComponentNamed
public class <xsl:value-of select="$service-sente"/>MessageValidator extends ServiceAdvice {

  @Override
  protected void beforeService( @Nonnull final Object object ) throws <xsl:value-of select="$service-sente"/>Exception {
    // validate message
    if ( object instanceof <xsl:value-of select="$service-sente"/>Message ) {
      final <xsl:value-of select="$service-sente"/>Message request = (<xsl:value-of select="$service-sente"/>Message) object;
      final Map&lt;String,String> validationErrorsByField = request.validate( );
      if ( !validationErrorsByField.isEmpty() ) {
        throw new <xsl:value-of select="$service-sente"/>ClientException( "ValidationError", validationErrorsByField.values().iterator().next() );
      }
    }
  }
}
</exsl:document>
<xsl:choose>
  <xsl:when test="/service-metadata/metadata/@protocol='json'">
    <exsl:document href="{$output-path}/{$service-lower}/src/main/java/com/eucalyptus/{$service-lower}/service/ws/{$service-sente}JsonBinding.java" method="text">/*
 * Copyright 2020 AppScale Systems, Inc
 *
 * Use of this source code is governed by a BSD-2-Clause
 * license that can be found in the LICENSE file or at
 * https://opensource.org/licenses/BSD-2-Clause
 */
package com.eucalyptus.<xsl:value-of select="$service-lower"/>.service.ws;

import com.eucalyptus.component.annotation.ComponentPart;
import com.eucalyptus.<xsl:value-of select="$service-lower"/>.common.<xsl:value-of select="$service-sente"/>;
import com.eucalyptus.ws.protocol.BaseJsonBinding;

/**
 *
 */
@ComponentPart( <xsl:value-of select="$service-sente"/>.class )
public class <xsl:value-of select="$service-sente"/>JsonBinding extends BaseJsonBinding {

  public <xsl:value-of select="$service-sente"/>JsonBinding() {
    super( "<xsl:value-of select="/service-metadata/metadata/@targetPrefix"/>" );
  }
}
</exsl:document>
    <exsl:document href="{$output-path}/{$service-lower}/src/main/java/com/eucalyptus/{$service-lower}/service/ws/{$service-sente}JsonPipeline.java" method="text">/*
 * Copyright 2020 AppScale Systems, Inc
 *
 * Use of this source code is governed by a BSD-2-Clause
 * license that can be found in the LICENSE file or at
 * https://opensource.org/licenses/BSD-2-Clause
 */
package com.eucalyptus.<xsl:value-of select="$service-lower"/>.service.ws;

import java.util.Collections;
import java.util.EnumSet;
import org.jboss.netty.channel.ChannelPipeline;
import com.eucalyptus.auth.principal.TemporaryAccessKey;
import com.eucalyptus.<xsl:value-of select="$service-lower"/>.service.config.<xsl:value-of select="$service-sente"/>Configuration;
import com.eucalyptus.component.annotation.ComponentPart;
import com.eucalyptus.<xsl:value-of select="$service-lower"/>.common.<xsl:value-of select="$service-sente"/>;
import com.eucalyptus.ws.server.JsonPipeline;
import com.eucalyptus.ws.util.HmacUtils.SignatureVersion;

/**
 *
 */
@ComponentPart(<xsl:value-of select="$service-sente"/>.class)
public class <xsl:value-of select="$service-sente"/>JsonPipeline extends JsonPipeline {

  public <xsl:value-of select="$service-sente"/>JsonPipeline() {
    super(
        "<xsl:value-of select="$service-lower"/>-json",
        "<xsl:value-of select="/service-metadata/metadata/@targetPrefix"/>",
        Collections.singleton( <xsl:value-of select="$service-sente"/>Configuration.SERVICE_PATH ),
        EnumSet.allOf( TemporaryAccessKey.TemporaryKeyType.class ),
        EnumSet.allOf( SignatureVersion.class ) );
  }

  @Override
  public ChannelPipeline addHandlers( final ChannelPipeline pipeline ) {
    super.addHandlers( pipeline );
    pipeline.addLast( "<xsl:value-of select="$service-lower"/>-json-binding", new <xsl:value-of select="$service-sente"/>JsonBinding( ) );
    return pipeline;
  }
}
</exsl:document>
  </xsl:when>
  <xsl:when test="/service-metadata/metadata/@protocol='query'">
    <exsl:document href="{$output-path}/{$service-lower}/src/main/java/com/eucalyptus/{$service-lower}/service/ws/{$service-sente}QueryBinding.java" method="text">/*
 * Copyright 2020 AppScale Systems, Inc
 *
 * Use of this source code is governed by a BSD-2-Clause
 * license that can be found in the LICENSE file or at
 * https://opensource.org/licenses/BSD-2-Clause
 */
package com.eucalyptus.<xsl:value-of select="$service-lower"/>.service.ws;

import com.eucalyptus.component.annotation.ComponentPart;
import com.eucalyptus.<xsl:value-of select="$service-lower"/>.common.<xsl:value-of select="$service-sente"/>;
import com.eucalyptus.ws.protocol.BaseQueryBinding;
import com.eucalyptus.ws.protocol.OperationParameter;

/**
 *
 */
@ComponentPart( <xsl:value-of select="$service-sente"/>.class )
public class <xsl:value-of select="$service-sente"/>QueryBinding extends BaseQueryBinding&lt;OperationParameter> {
  //TODO verify namespace pattern is correct for ns <xsl:value-of select="$service-ns"/>
  static final String NAMESPACE_PATTERN = "http://<xsl:value-of select="$service-lower"/>.amazonaws.com/doc/%s/";
  static final String DEFAULT_VERSION = "<xsl:value-of select="$service-version"/>";
  static final String DEFAULT_NAMESPACE = String.format( NAMESPACE_PATTERN, DEFAULT_VERSION );

  public <xsl:value-of select="$service-sente"/>QueryBinding() {
    super( NAMESPACE_PATTERN, DEFAULT_VERSION, OperationParameter.Action, OperationParameter.Operation );
  }
}
</exsl:document>
    <exsl:document href="{$output-path}/{$service-lower}/src/main/java/com/eucalyptus/{$service-lower}/service/ws/{$service-sente}QueryPipeline.java" method="text">/*
 * Copyright 2020 AppScale Systems, Inc
 *
 * Use of this source code is governed by a BSD-2-Clause
 * license that can be found in the LICENSE file or at
 * https://opensource.org/licenses/BSD-2-Clause
 */
package com.eucalyptus.<xsl:value-of select="$service-lower"/>.service.ws;

import java.util.EnumSet;
import org.jboss.netty.channel.ChannelPipeline;
import com.eucalyptus.auth.principal.TemporaryAccessKey;
import com.eucalyptus.<xsl:value-of select="$service-lower"/>.service.config.<xsl:value-of select="$service-sente"/>Configuration;
import com.eucalyptus.component.annotation.ComponentPart;
import com.eucalyptus.<xsl:value-of select="$service-lower"/>.common.<xsl:value-of select="$service-sente"/>;
import com.eucalyptus.ws.server.QueryPipeline;

/**
 *
 */
@ComponentPart(<xsl:value-of select="$service-sente"/>.class)
public class <xsl:value-of select="$service-sente"/>QueryPipeline extends QueryPipeline {

  public <xsl:value-of select="$service-sente"/>QueryPipeline() {
    super(
        "<xsl:value-of select="$service-lower"/>-query",
        <xsl:value-of select="$service-sente"/>Configuration.SERVICE_PATH,
        EnumSet.allOf( TemporaryAccessKey.TemporaryKeyType.class ) );
  }

  @Override
  public ChannelPipeline addHandlers( final ChannelPipeline pipeline ) {
    super.addHandlers( pipeline );
    pipeline.addLast( "<xsl:value-of select="$service-lower"/>-query-binding", new <xsl:value-of select="$service-sente"/>QueryBinding( ) );
    return pipeline;
  }
}
</exsl:document>
  </xsl:when>
  <xsl:when test="/service-metadata/metadata/@protocol='rest-xml'">
    <exsl:document href="{$output-path}/{$service-lower}/src/main/java/com/eucalyptus/{$service-lower}/service/ws/{$service-sente}RestXmlBinding.java" method="text">/*
 * Copyright 2020 AppScale Systems, Inc
 *
 * Use of this source code is governed by a BSD-2-Clause
 * license that can be found in the LICENSE file or at
 * https://opensource.org/licenses/BSD-2-Clause
 */
package com.eucalyptus.<xsl:value-of select="$service-lower"/>.service.ws;

import javax.annotation.Nonnull;
import com.eucalyptus.component.annotation.ComponentPart;
import com.eucalyptus.<xsl:value-of select="$service-lower"/>.common.<xsl:value-of select="$service-sente"/>;
import com.eucalyptus.<xsl:value-of select="$service-lower"/>.common.msgs.ErrorResponse;
import com.eucalyptus.<xsl:value-of select="$service-lower"/>.service.config.<xsl:value-of select="$service-sente"/>Configuration;
import com.eucalyptus.ws.protocol.BaseRestXmlBinding;

/**
 *
 */
@ComponentPart( <xsl:value-of select="$service-sente"/>.class )
public class <xsl:value-of select="$service-sente"/>RestXmlBinding extends BaseRestXmlBinding&lt;ErrorResponse> {
  //TODO verify namespace pattern is correct for ns <xsl:value-of select="$service-ns"/>
  static final String NAMESPACE_PATTERN = "http://<xsl:value-of select="$service-lower"/>.amazonaws.com/doc/%s/";
  static final String DEFAULT_VERSION = "<xsl:value-of select="$service-version"/>";
  static final String DEFAULT_NAMESPACE = String.format( NAMESPACE_PATTERN, DEFAULT_VERSION );

  public <xsl:value-of select="$service-sente"/>RestXmlBinding() {
    super( NAMESPACE_PATTERN, DEFAULT_VERSION, <xsl:value-of select="$service-sente"/>Configuration.SERVICE_PATH, true );
  }

  @Override
  protected ErrorResponse errorResponse(
               final String requestId,
      @Nonnull final String type,
      @Nonnull final String code,
      @Nonnull final String message ) {
    final ErrorResponse errorResponse = new ErrorResponse( );
    errorResponse.setRequestId( requestId );
    final com.eucalyptus.<xsl:value-of select="$service-lower"/>.common.msgs.Error error = new com.eucalyptus.<xsl:value-of select="$service-lower"/>.common.msgs.Error();
    error.setType( type );
    error.setCode( code );
    error.setMessage( message );
    errorResponse.getError( ).add( error );
    return errorResponse;
  }
}
</exsl:document>
    <exsl:document href="{$output-path}/{$service-lower}/src/main/java/com/eucalyptus/{$service-lower}/service/ws/{$service-sente}RestXmlPipeline.java" method="text">/*
 * Copyright 2020 AppScale Systems, Inc
 *
 * Use of this source code is governed by a BSD-2-Clause
 * license that can be found in the LICENSE file or at
 * https://opensource.org/licenses/BSD-2-Clause
 */
package com.eucalyptus.<xsl:value-of select="$service-lower"/>.service.ws;

import java.util.EnumSet;
import org.jboss.netty.channel.ChannelPipeline;
import com.eucalyptus.auth.principal.TemporaryAccessKey;
import com.eucalyptus.<xsl:value-of select="$service-lower"/>.service.config.<xsl:value-of select="$service-sente"/>Configuration;
import com.eucalyptus.component.annotation.ComponentPart;
import com.eucalyptus.<xsl:value-of select="$service-lower"/>.common.<xsl:value-of select="$service-sente"/>;
import com.eucalyptus.ws.server.RestXmlPipeline;

/**
 *
 */
@ComponentPart(<xsl:value-of select="$service-sente"/>.class)
public class <xsl:value-of select="$service-sente"/>RestXmlPipeline extends RestXmlPipeline {

  public <xsl:value-of select="$service-sente"/>RestXmlPipeline() {
    super(
        "<xsl:value-of select="$service-lower"/>-rest-xml",
        <xsl:value-of select="$service-sente"/>Configuration.SERVICE_PATH,
        EnumSet.allOf( TemporaryAccessKey.TemporaryKeyType.class ) );
  }

  @Override
  public ChannelPipeline addHandlers( final ChannelPipeline pipeline ) {
    super.addHandlers( pipeline );
    pipeline.addLast( "<xsl:value-of select="$service-lower"/>-rest-xml-binding", new <xsl:value-of select="$service-sente"/>RestXmlBinding( ) );
    return pipeline;
  }
}
</exsl:document>
  </xsl:when>
  <xsl:when test="/service-metadata/metadata/@protocol='rest-json'">
    <exsl:document href="{$output-path}/{$service-lower}/src/main/java/com/eucalyptus/{$service-lower}/service/ws/{$service-sente}RestJsonBinding.java" method="text">/*
 * Copyright 2020 AppScale Systems, Inc
 *
 * Use of this source code is governed by a BSD-2-Clause
 * license that can be found in the LICENSE file or at
 * https://opensource.org/licenses/BSD-2-Clause
 */
package com.eucalyptus.<xsl:value-of select="$service-lower"/>.service.ws;

import com.eucalyptus.component.annotation.ComponentPart;
import com.eucalyptus.<xsl:value-of select="$service-lower"/>.common.<xsl:value-of select="$service-sente"/>;
import com.eucalyptus.<xsl:value-of select="$service-lower"/>.service.config.<xsl:value-of select="$service-sente"/>Configuration;
import com.eucalyptus.ws.protocol.BaseRestJsonBinding;

/**
 *
 */
@ComponentPart( <xsl:value-of select="$service-sente"/>.class )
public class <xsl:value-of select="$service-sente"/>RestJsonBinding extends BaseRestJsonBinding {

  public <xsl:value-of select="$service-sente"/>RestJsonBinding() {
    super( <xsl:value-of select="$service-sente"/>Configuration.SERVICE_PATH );
  }
}
</exsl:document>
    <exsl:document href="{$output-path}/{$service-lower}/src/main/java/com/eucalyptus/{$service-lower}/service/ws/{$service-sente}RestJsonPipeline.java" method="text">/*
 * Copyright 2020 AppScale Systems, Inc
 *
 * Use of this source code is governed by a BSD-2-Clause
 * license that can be found in the LICENSE file or at
 * https://opensource.org/licenses/BSD-2-Clause
 */
package com.eucalyptus.<xsl:value-of select="$service-lower"/>.service.ws;

import java.util.EnumSet;
import org.jboss.netty.channel.ChannelPipeline;
import com.eucalyptus.auth.principal.TemporaryAccessKey;
import com.eucalyptus.<xsl:value-of select="$service-lower"/>.service.config.<xsl:value-of select="$service-sente"/>Configuration;
import com.eucalyptus.component.annotation.ComponentPart;
import com.eucalyptus.<xsl:value-of select="$service-lower"/>.common.<xsl:value-of select="$service-sente"/>;
import com.eucalyptus.ws.server.RestJsonPipeline;

/**
 *
 */
@ComponentPart(<xsl:value-of select="$service-sente"/>.class)
public class <xsl:value-of select="$service-sente"/>RestJsonPipeline extends RestJsonPipeline {

  public <xsl:value-of select="$service-sente"/>RestJsonPipeline() {
    super(
        "<xsl:value-of select="$service-lower"/>-rest-json",
        <xsl:value-of select="$service-sente"/>Configuration.SERVICE_PATH,
        EnumSet.allOf( TemporaryAccessKey.TemporaryKeyType.class ) );
  }

  @Override
  public ChannelPipeline addHandlers( final ChannelPipeline pipeline ) {
    super.addHandlers( pipeline );
    pipeline.addLast( "<xsl:value-of select="$service-lower"/>-rest-json-binding", new <xsl:value-of select="$service-sente"/>RestJsonBinding( ) );
    return pipeline;
  }
}
</exsl:document>
  </xsl:when>
  <xsl:otherwise>
          <xsl:message terminate="yes">Unknown protocol <xsl:value-of select="/service-metadata/metadata/@protocol"/> (add support for this kind of api)</xsl:message>
  </xsl:otherwise>
</xsl:choose>
<xsl:if test="/service-metadata/metadata[@protocol='query' or @protocol='rest-xml']">
    <exsl:document href="{$output-path}/{$service-lower}/src/test/java/com/eucalyptus/{$service-lower}/service/ws/{$service-sente}BindingTest.groovy" method="text">/*
 * Copyright 2020 AppScale Systems, Inc
 *
 * Use of this source code is governed by a BSD-2-Clause
 * license that can be found in the LICENSE file or at
 * https://opensource.org/licenses/BSD-2-Clause
 */
package com.eucalyptus.<xsl:value-of select="$service-lower"/>.service.ws

import com.eucalyptus.ws.protocol.QueryBindingTestSupport
import org.junit.Test

/**
 *
 */
class <xsl:value-of select="$service-sente"/>BindingTest extends QueryBindingTestSupport {

  @Test
  void testValidBinding() {
    URL resource = <xsl:value-of select="$service-sente"/>BindingTest.class.getResource( '/<xsl:value-of select="$service-lower"/>-binding.xml' )
    assertValidBindingXml( resource )
  }

  @Test
  void testValidQueryBinding() {
    URL resource = <xsl:value-of select="$service-sente"/>BindingTest.class.getResource( '/<xsl:value-of select="$service-lower"/>-binding.xml' )
    assertValidQueryBinding( resource )
  }

  @Test
  void testInternalRoundTrip() {
    URL resource = <xsl:value-of select="$service-sente"/>BindingTest.class.getResource( '/<xsl:value-of select="$service-lower"/>-binding.xml' )
    assertValidInternalRoundTrip( resource )
  }
}
</exsl:document>
</xsl:if>
  </xsl:template>

</xsl:stylesheet>
