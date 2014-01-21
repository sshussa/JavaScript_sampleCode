<%@page import="org.apache.axis.tools.ant.foreach.ForeachTask"%>
<%@page import="org.apache.velocity.runtime.directive.Foreach"%>

<%
    /*

    Copyright (C) 2002 Fry Inc., All Rights Reserved.
    Purpose:
    The body of the product photo gallery (included by product.jsp).
    */
%>

<%@ page
	import="com.fry.ocp.catalog.*,
                 com.fry.ocp.util.StringUtil,
                 com.fry.wp.multisite.site.SiteManager,
                 com.fry.wp.multisite.util.i18n.I18NUtil,
                 com.fry.wp.multisite.utils.MultiSiteWebUtil,
                 com.fry.wp.multisite.utils.ProductVariantComparator,
                 com.fry.ocp.catalog.ProductVariant"
                %>
<%@ page import="com.fry.wp.multisite.util.ProductUtil"%>
<%@ page import="java.util.*"%>

<%@ taglib uri="/WEB-INF/ocp-site.tld" prefix="site"%>
<%@ taglib uri="/WEB-INF/ocp-html.tld" prefix="html"%>
<%@ taglib uri="/WEB-INF/ocp-user.tld" prefix="user"%>
<%@ taglib uri="/WEB-INF/ocp-i18n.tld" prefix="i18n"%>
<%@ taglib uri="/WEB-INF/ocp-cms.tld" prefix="cms"%>
<%@ taglib uri="/WEB-INF/ocp-logic.tld" prefix="logic"%>
<%@ taglib uri="/WEB-INF/ocp-cache.tld" prefix="cache"%>
<site:site id="currentSite" />
<i18n:bundle base="com.fry.wp.multisite.i18n.WPResourceBundle" locale='<%=SiteManager.getLocale(currentSite, request)%>' />

<% 
	/*
		Get product
	*/
	String productId = (request.getParameter("productId") == null) ? "" : request.getParameter("productId");

	Product product;
	if (!StringUtil.isEmpty(productId) && StringUtil.isLong(productId)) {
		try {
			product = ProductManager.getProduct(Long.parseLong(productId));
		} catch (Exception ex) {
			product = null;
			System.out.println(ex.getMessage());
		}
	} else {
		throw new javax.servlet.jsp.JspException("The productId was invalid. It's value was " + productId);
	}
	
	 /*
    Get larger image
     */
     Map largeImages = MultiSiteWebUtil.populateDefaultImageMappings(currentSite, product);
     
     Iterator images = largeImages.values().iterator();
     
     ArrayList thumbnailImages =  MultiSiteWebUtil.getMDMThumbImages(currentSite, product);
    
     

%>

<div id="ig-panel" class="ig-panel overlay" >

	<img src="" id="productImageTransition_from" class="productGalery_image">
	<img src="" id="productImageTransition_to" class="productGalery_image">
	<logic:iterator id="img" collection='<%=images%>' indexId='index' type="String">
		<%--<logic:equal name="index" value="0"> --%>
			<img src="<%=img%>" id="<%="productImageTransition"+"_" +index%>" class="productGalery_image">
		<%--</logic:equal> --%>
	</logic:iterator>
	
	<div id="productFlyoutClose" class="fadeElement js_closeButton">
		<div class="opac"> </div>
		<div class="closeButton">9</div>
	</div>


	<div id="productGalery_expand" class="fadeElement">
		<div class="opac"> </div>
		<div class="icon_productGalery expandDiv" > </div>
	</div>


	<div id="productGalery_arrowLeft" class="fadeElement">
		<div class="opac "> </div>
		<div class="icon_productGalery arrowDiv" > </div>
	</div>
	<div id="productGalery_arrowRight" class="fadeElement">
		<div class="opac"> </div>
		<div class="icon_productGalery arrowDiv" > </div>
	</div>

	<div class="productGallery_thumbnail_wrapper fadeElement">
		<div class="supportDiv opac"></div>
		<div id="productGalery_div" class="supportDiv">
			<ul id="productGalery_thumbnails">
				<logic:iterator id="thumb" collection='<%=thumbnailImages%>' indexId='index' type="String">
					<li><img src="<%=thumb%>"></li>
				</logic:iterator>
			<ul>				

		</div>
	</div>

</div>


<script type="text/javascript">
<%
images = largeImages.values().iterator();
	String imageArray = "[";
	while (images.hasNext()) {
	    String image = (String)images.next();
	    imageArray += "'" + image + "'";
	    if(images.hasNext())
	    	imageArray += ",";
	}
	imageArray += "]";
%>

$(document).ready(function(){
	binder.disolveGroup.create(
		"productGalery",
		{
		imgAry:<%=imageArray%>
		}
	);
})	
</script>


