<%@ page
	import="com.fry.ocp.catalog.Product,com.fry.ocp.catalog.ProductManager,com.fry.ocp.engine.catalog.ProductConfig,com.fry.ocp.engine.util.OCPConfig,com.fry.ocp.util.StringUtil,com.fry.wp.multisite.catalog.WhirlpoolProductManager,com.fry.wp.multisite.site.SiteUtil,com.fry.ocp.cms.Page,com.fry.ocp.cms.PageManager,com.fry.ocp.catalog.Category,com.fry.ocp.catalog.CategoryManager,com.fry.ocp.util.ConvertUtil"%>

<%
	 /*

	 Copyright (C) 2002 Fry Inc., All Rights Reserved.

	 Purpose:
	 The page which generates the HTML for 4.1 Product Page Template 1 "Dynamic Top Product Page"

	 */
%>

<%@ taglib uri='/WEB-INF/ocp-template.tld' prefix='template'%>
<%@ taglib uri='/WEB-INF/ocp-user.tld' prefix='user'%>
<%@ taglib uri='/WEB-INF/ocp-cms.tld' prefix='cms'%>
<%@ taglib uri="/WEB-INF/ocp-pipeline.tld" prefix="pipeline"%>
<%@ taglib uri="/WEB-INF/ocp-site.tld" prefix="site"%>
<%@ taglib uri="/WEB-INF/ocp-logic.tld" prefix="logic"%>

<site:site id="currentSite" />

<%
	String productId = StringUtil.trim(request.getParameter("productId"));
	String categoryId = StringUtil.trim(request.getParameter("categoryId"));
	String parentCategoryId = StringUtil.trim(request.getParameter("parentCategoryId"));
	Product product = ProductManager.getProduct(Long.parseLong(productId));
	Category category = CategoryManager.findCategory(ConvertUtil.convertLong(categoryId).longValue(), true);

	if (WhirlpoolProductManager.PRODUCT_TYPE_ACCESSORY != ConvertUtil.convertInteger(product.getString(WhirlpoolProductManager.PRODUCT_TYPE_KEY)).intValue()) {
		if (!SiteUtil.checkSiteAccess(currentSite, product)) {
			response.sendError(404);
		}
	}

	// Page title, description and keyword meta tags
	String pageTitle = (category == null ? "" : category.getString("DESCRIPTION")) + " "
	      + product.getString("STYLE") + " from " + currentSite.getSiteName();
	String metaDescription = StringUtil.trim(product.getString("DESCRIPTION"));
	String metaKeywords = StringUtil.trim(product.getString("KEYWORD"));

	Page categoryPage = null;
	if (!StringUtil.isEmpty(categoryId)) {
		String requestPath = SiteUtil.getUniqueName(currentSite, "/catalog/category.jsp?categoryId=" + categoryId);
		categoryPage = PageManager.findPage(requestPath);

		if (categoryPage == null && !StringUtil.isEmpty(parentCategoryId)) {
			requestPath = SiteUtil.getUniqueName(currentSite, "/catalog/category.jsp?parentCategoryId=" + parentCategoryId + "&categoryId=" + categoryId);
			categoryPage = PageManager.findPage(requestPath);
		}
	}

	if (categoryPage != null && !StringUtil.isEmpty(categoryPage.getDescription())) {
		metaDescription = StringUtil.trim(categoryPage.getDescription());
		metaKeywords = StringUtil.trim(categoryPage.getKeywords());
	}

	request.setAttribute("pageTitle", pageTitle);
	request.setAttribute("keywordMetaTag", metaKeywords);
	request.setAttribute("descriptionMetaTag", metaDescription);
	request.setAttribute("src_page", "product");
	
%>

<template:templateConfig id="templateConfig" templateKeyLabel="PRODUCT_PAGE_TEMPLATE_ID" />
<logic:notnull object="<%=templateConfig%>">
	<template:insert template='<%=templateConfig.getJSPTemplateName()%>'>
		<template:put name='title' content='<%=pageTitle%>' direct='true' />
		<logic:iterator id="templatePage" collection='<%=templateConfig.getJSPTemplateConfig()%>' indexId='configIndex'
			type='com.fry.wp.multisite.util.template.JSPTemplateConfig'>
			<template:put name='<%=templatePage.getName()%>' content='<%=templatePage.getContent()%>'
				direct='<%=String.valueOf(templatePage.isDirect())%>' />
		</logic:iterator>
	</template:insert>
</logic:notnull>
