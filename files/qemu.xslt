<?xml version="1.0" ?>
<xsl:stylesheet version="1.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:output omit-xml-declaration="yes" indent="yes"/>
  <xsl:template match="node()|@*">
     <xsl:copy>
       <xsl:apply-templates select="node()|@*"/>
     </xsl:copy>
  </xsl:template>
  <xsl:template match="devices/channel">
   <xsl:element name="channel">
      <xsl:attribute name="type">
        <xsl:value-of select="'unix'"/>
      </xsl:attribute>
    <xsl:element name="source">
      <xsl:attribute name="mode">
        <xsl:value-of select="'bind'"/>
      </xsl:attribute>
    </xsl:element>
    <xsl:element name="target">
      <xsl:attribute name="type">
        <xsl:value-of select="'virtio'"/>
      </xsl:attribute>
      <xsl:attribute name="name">
        <xsl:value-of select="'org.qemu.guest_agent.0'"/>
      </xsl:attribute>
    </xsl:element>
   </xsl:element>
  </xsl:template>
</xsl:stylesheet>
