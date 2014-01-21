<%@ page import="com.fry.ocp.catalog.Category,
					  com.fry.ocp.catalog.Product,
					  com.fry.ocp.catalog.ProductManager,
					  com.fry.ocp.util.StringUtil,
					  com.fry.wp.multisite.catalog.WhirlpoolProductAttributeGroupManager,
					  com.fry.wp.multisite.catalog.WhirlpoolProductManager,
					  com.fry.wp.multisite.catalog.ProductFeature,
					  com.fry.wp.multisite.site.SiteManager,
					  com.fry.wp.multisite.util.ProductFeaturesKeyComparator,
					  com.fry.wp.multisite.utils.CatalogUtils,
					  com.fry.wp.multisite.util.i18n.I18NUtil,
					  com.fry.wp.multisite.utils.MultiSiteWebUtil,
					  java.util.LinkedHashMap,
                 com.fry.ocp.cms.CMSManager,
                 com.fry.wp.multisite.site.SiteUtil,
				 com.fry.ocp.cms.PageManager,
                 com.fry.ocp.cms.Page,
                 com.fry.ocp.cms.Section" %>
<%@ page import="java.util.List" %>
<%@ page import="java.util.ArrayList" %>
<%@ page import="java.util.Set" %>
<%@ page import="java.util.SortedSet" %>
<%@ page import="java.util.TreeSet" %>
<%@ page import="java.util.Comparator" %>
<%@ page import="java.util.Iterator" %>
<%@ page import="com.fry.wp.multisite.util.ProductUtil" %>
<%@ page import="com.fry.wp.multisite.util.SEOUtil" %>
<%@ page import="com.fry.ocp.catalog.CategoryManager" %>
<%
	/*

 Copyright (C) 2005 Fry Inc., All Rights Reserved.

 Purpose:
 To display additional product information using Tab Component such as:
 Description, Features, etc.

 */
%>

<%@ taglib uri="/WEB-INF/ocp-html.tld" prefix="html" %>
<%@ taglib uri="/WEB-INF/ocp-catalog.tld" prefix="catalog" %>
<%@ taglib uri="/WEB-INF/ocp-command.tld" prefix="command" %>
<%@ taglib uri="/WEB-INF/ocp-logic.tld" prefix="logic" %>
<%@ taglib uri="/WEB-INF/ocp-util.tld" prefix="util" %>
<%@ taglib uri="/WEB-INF/ocp-user.tld" prefix="user" %>
<%@ taglib uri="/WEB-INF/ocp-site.tld" prefix="site" %>
<%@ taglib uri="/WEB-INF/ocp-cms.tld" prefix="cms" %>
<%@ taglib uri="/WEB-INF/ocp-i18n.tld" prefix="i18n" %>

<site:site id="currentSite"/>
<i18n:bundle base="com.fry.wp.multisite.i18n.WPResourceBundle"
				 locale='<%=SiteManager.getLocale(currentSite, request)%>'/>
<user:user id="user"/>
<%
	/*
		Constants
		*/
	final String PANEL1 = "panel1";
	final String PANEL2 = "panel2";
	final String PANEL3 = "panel3";
	final String PANEL4 = "panel4";
	final String PANEL5 = "panel5";
	final String PANEL6 = "panel6";
	final String PANEL7 = "panel7";

	String baseImagePath = currentSite.getImagePath(); //storefront image directory, preceded by domain //

	/*
		Get product
		*/
	String productId = (request.getParameter("productId") == null) ? "" : request.getParameter("productId");
	LinkedHashMap specifications = (LinkedHashMap)request.getAttribute("specifications");
	LinkedHashMap specifications1 = (LinkedHashMap)request.getAttribute("specifications1");
	/*
		 Get category and parent category
		  */
	String parentCategoryId = (request.getParameter("parentCategoryId") == null) ? "" : request.getParameter("parentCategoryId");
	String categoryId = (request.getParameter("categoryId") == null) ? "" : request.getParameter("categoryId");
	//Category parentCategory = StringUtil.isLong(parentCategoryId) ? CategoryManager.getCategory(Long.parseLong(parentCategoryId)) : null;
	//Category category = StringUtil.isLong(categoryId) ? CategoryManager.getCategory(Long.parseLong(categoryId)) : null;

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
	String prodLongDesc;
	LinkedHashMap features;
	//LinkedHashMap specifications;
	//LinkedHashMap specifications1;
	List entityFiles;
	List relatedProducts;
	List productAccessories;

	String defaultTab = "";
	boolean showDesciptionTab = true;
	boolean showFeaturesTab = true;
	boolean showSpecificationsTab = true;
	boolean showLiteratureTab = true;
	boolean showReviewsTab = false;//Commented out the reviews tab.
	boolean showRelatedTab = true;
	boolean showAccessoriesTab = true;
	boolean showVideosTab = false;
	com.fry.ocp.catalog.EntityFile useCareFile = null;

	if (product != null) {
		/*
				Get long product description
				 */
		prodLongDesc = product.getString("LONG_DESCRIPTION");
		/*
				Get Features list
				 */
		try {
			features = (LinkedHashMap)WhirlpoolProductAttributeGroupManager.findProductAttributeGroupsSorted(Long.parseLong(productId), "SF1", true);
		} catch (Exception ex) {
			features = null;
			System.out.println(ex.getMessage());
		}

		
		/*
			Get Literature and videos for product
		*/
		try {
			entityFiles = product.getEntityFiles(true);

		} catch (Exception ex) {
			entityFiles = null;
			System.out.println(ex.getMessage());
		}

		/*
			Get Related Product list
		*/
		relatedProducts = WhirlpoolProductManager.getRelatedProducts(Long.parseLong(productId), true);
		/*
			Get Accessories for product
		*/
		productAccessories = WhirlpoolProductManager.getProductAccessories(Long.parseLong(productId), true);

		/*
			Check whether or not show Features Tab
		*/
		if (features == null || features.size() == 0 || (features.keySet().iterator().hasNext() && features.keySet().iterator().next() == null)) {
			showFeaturesTab = false;
		} else if ("".equals(defaultTab)) {
			defaultTab = PANEL1;

		}

		/*
			Check whether or not show Literature Tab
		*/
		if (entityFiles == null || entityFiles.size() == 0) {
			showLiteratureTab = false;
		} else if ("".equals(defaultTab)) {
			defaultTab = PANEL2;
		}

		if (entityFiles != null){
			for(int i=0;i<entityFiles.size();i++){
				com.fry.ocp.catalog.EntityFile entityFile = (com.fry.ocp.catalog.EntityFile) entityFiles.get(i);
				String referenceKey = entityFile.getString("REFERENCE_KEY");
				if (WhirlpoolProductManager.REF_KEY_VIDEO.equals(referenceKey)) {
					showVideosTab = true;
				} else if ("USECARE".equals(referenceKey)) {
					useCareFile = entityFile;
				}
			}
		}
		/*
		Check whether or not show accessories Tab
		 */
		if (productAccessories == null || productAccessories.size() == 0) {
			showAccessoriesTab = false;
		} else if ("".equals(defaultTab)) {
			defaultTab = PANEL3;

		}

		/*
			Check whether or not show relatedProducts Tab
		*/
		if (relatedProducts == null || relatedProducts.size() == 0) {
			showRelatedTab = false;
		} else if ("".equals(defaultTab)) {
			defaultTab = PANEL4;

		}
		/*
			Check whether or not show Description Tab
		 */
		if (StringUtil.isEmpty(prodLongDesc)) {
			showDesciptionTab = false;
		} else if ("".equals(defaultTab)) {
			defaultTab = PANEL5;

		}
		/*
			Check whether or not show Specifications Tab
		*/

		if ((specifications == null || specifications.size() == 0 || (specifications.keySet().iterator().hasNext() && specifications.keySet().iterator().next() == null)) &&
				(specifications1 == null || specifications1.size() == 0 || (specifications1.keySet().iterator().hasNext() && specifications1.keySet().iterator().next() == null))) {
			showSpecificationsTab = false;
		} else if ("".equals(defaultTab)) {
			defaultTab = PANEL6;

		}

		List listCategory = product.getCategories();
		Category parentCategory = CatalogUtils.getRootCategoryFromProduct(product);
		Category category = null;
		if (listCategory != null && listCategory.size() > 0) {
			category = (Category) listCategory.get(0);
		}
		String pageTitle = (String) request.getAttribute("pageTitle");
		String categoryName = MultiSiteWebUtil.replaceHtmlCharacters(category == null ? "" : category.getString("DESCRIPTION"));
		String parentCategoryName = MultiSiteWebUtil.replaceHtmlCharacters(parentCategory == null ? "" : parentCategory.getString("DESCRIPTION"));
		String productModel = product.getString("STYLE");
		String productName = product.getString("NAME");
%>
<% final String baseImagePathEx = request.getContextPath() + baseImagePath; %>
<% String devBaseImagePath = "/assets/amana/images/sitesection/product/"; %>

<% String warrantyContent = ""; %>

<!-- START Features panel -->
<% if (showFeaturesTab) {
%>
<!-- "add-features"  just a tem. solution until rebuilfd is complete. will change to "key-features" for top five and then add-features will follow. -->

<jsp:include page="product_amana_key_features.jsp"> 
      <jsp:param name="productId" value="<%=productId%>"/>   
 </jsp:include> 

 
<div id="add-features" class="section">
	<h2>Explore Key Features</h2>
	<table cellpadding=0 cellspacing=0 border=0 class="features"><tr>

		<%
			// TSK0085: The 'Warranty' features should always be last
			//	Set keySetFeatures = new TreeSet(new ProductFeaturesKeyComparator());
			//	keySetFeatures.addAll(features.keySet());
			Set keySetFeatures = features.keySet();

		%>
		<logic:iterator id="keyIter" type="java.lang.Object" collection="<%=keySetFeatures%>" >

			<%
				SortedSet prodFeatures = (SortedSet) features.get(keyIter);
				 boolean isWarranty = false;
				if("Warranty".equals(keyIter)) {
					isWarranty = true;
				}
				// Get the product feature list
				Iterator it = prodFeatures.iterator();
				List longDescList = new ArrayList();
				while (it.hasNext()) {
					ProductFeature pf = (ProductFeature)it.next();
					if(isWarranty){
						warrantyContent = pf.getDisplayName();
					}
					if ("Benefit".equals(pf.getType()) && !StringUtil.isEmpty(pf.getValue())){
						longDescList.add(pf);
					}
				}
				int counter = -1;
				%>
				<logic:iterator id="prodFeature" type="com.fry.wp.multisite.catalog.ProductFeature"
									 collection="<%=prodFeatures%>" >
					<%if (!"Benefit".equals(prodFeature.getType())) {
						boolean showMoreHref = false;
						String moreHref = "";
						String longDesc = "";
						for (int i = 0; i < longDescList.size(); ++i) {
							ProductFeature pf = (ProductFeature)longDescList.get(i);
							longDesc = pf.getValue();
							
							if (prodFeature.getDisplayName().equals(pf.getDisplayName())) {
								showMoreHref = true;
								moreHref = "javascript:openWindow('/catalog/product_amana_feature_popup.jsp?parentCategoryId="+parentCategoryId+"&categoryId="+categoryId+"&productId="+productId+"&featureKey="+ pf.getProductAttributeId() +"','product_popup',440,300)";
								break;
							}
						}
					%>
					
					<%if (!isWarranty) { 
						counter++;
						if(counter == 3) {
							counter=0;
						%>
							</tr><tr>
						<%
						
						}
						
					%>
						<td valign="top">
						<h4><%=prodFeature.getDisplayName()%></h4>
						<%if (showMoreHref) { %>
							<p><%=longDesc%></p>
						<%}%>
						</td>
					<%}%>
					
					<%
						}
					%>
				</logic:iterator>

			
		</logic:iterator>
	</tr></table>
</div>
<% } %>
<!-- END Features panel -->

<!-- START Specifications panel -->
<% if (showSpecificationsTab) { %>

<div id="specifications" class="section">
	<h2>Specifications Guide</h2>
	<div id="table-wrapper">
	<%
		Set keySetSpecs = specifications.keySet();
		Set keySetSpecs1 = specifications1.keySet();
	%>
	<logic:iterator id="keySpec" type="java.lang.Object" collection="<%=keySetSpecs%>">
		<%
			SortedSet prodSpecs = (SortedSet) specifications.get(keySpec);
			int index = 0;
		%>

		<table cellpadding="0" cellspacing="0" class="spec-table">
			<thead>
				<tr>
					<th colspan="2"><%=keySpec%></th>
				</tr>
			</thead>
			<tbody>
			<logic:iterator id="prodSpec" type="com.fry.wp.multisite.catalog.ProductFeature" collection="<%=prodSpecs%>">
				<tr>
					<td class="row-title"><%=prodSpec.getDisplayName()%></td>
					<td><%=prodSpec.getValue()%></td>
					<%
						index++;
					%>
				</tr>
			</logic:iterator>
			</tbody>
		</table>
	</logic:iterator>

	<!--Electrical Requirements.-->
	<logic:iterator id="keySpec" type="java.lang.Object" collection="<%=keySetSpecs1%>">
		<%
			SortedSet prodSpecs = (SortedSet) specifications1.get(keySpec);
			int index = 0;
		%>

		<h5><%=keySpec%></h5>
		<ul>
			<logic:iterator id="prodSpec" type="com.fry.wp.multisite.catalog.ProductFeature" collection="<%=prodSpecs%>">

				<li><%=prodSpec.getValue()%></li>
				<%
					index++;
				%>

			</logic:iterator>
		</ul>
	</logic:iterator>
	</div>

	<div id="spec-right-col">
		<% String warrantyDocumentUrl = "";
		String warrantyOnClick = "";
		String warrantyDisplayName = "";
		boolean isWarranty = false;
		%>
		<div id="guides">
			<h5>Guides</h5>
			<ul class="guides">
				<logic:iterator id="file" type="com.fry.ocp.catalog.EntityFile" collection="<%=entityFiles%>">
					<%
						String referenceKey = file.getString("REFERENCE_KEY");
						String dirPrefix = "/";
						String docType = "";
						boolean hasDocument = false;
						if ("USECARE".equals(referenceKey)) {
							dirPrefix = "/" + WhirlpoolProductManager.DIRECTORY_PREFIX_USECARE + "/";
							docType = "Use and Care";
							hasDocument = true;
						} else if ("INSTALLGUIDE".equals(referenceKey)) {
							dirPrefix = "/" + WhirlpoolProductManager.DIRECTORY_PREFIX_INSTALLGUIDE + "/";
							docType = "Installation Instructions";
							hasDocument = true;
						} else if ("ENERGYGUIDE".equals(referenceKey)) {
							dirPrefix = "/" + WhirlpoolProductManager.DIRECTORY_PREFIX_ENERGYGUIDE + "/";
							docType = "Energy Guide";
							hasDocument = true;
						} else if ("DIMENSIONGUIDE".equals(referenceKey)) {
							dirPrefix = "/" + WhirlpoolProductManager.DIRECTORY_PREFIX_DIMENSIONGUIDE + "/";
							docType = "Dimension Guide";
							hasDocument = true;
						}
						// TSK0030 Added by Phuong Ngo Thi Bich on 10/04/07
						else if ("COMMERCIALSPECIFICATIONS".equals(referenceKey)) {
							dirPrefix = "/" + WhirlpoolProductManager.DIRECTORY_PREFIX_COMMERCIALSPECIFICATIONS + "/";
							docType = "Commercial Specifications";
							hasDocument = true;
						}
						// End TSK0030 Added by Phuong Ngo Thi Bich on 10/04/07
						// Start "Show WARRANTY" Added by Chuong Nguyen on 09/09/08
						else if ("WARRANTY".equals(referenceKey)) {
							dirPrefix = "/" + WhirlpoolProductManager.DIRECTORY_PREFIX_WARRANTY + "/";
							docType = "Warranty";
							isWarranty = true;
						}
						// End "Show WARRANTY" Added by Chuong Nguyen on 09/09/08
						//Additional Document Types: Buy Guide, Specification Sheet
						else if (WhirlpoolProductManager.REF_KEY_BUYGUIDE.equals(referenceKey)) {
							dirPrefix = "/" + WhirlpoolProductManager.DIRECTORY_PREFIX_BUYGUIDE + "/";
							docType = "Buy Guide";
							hasDocument = true;
						}
						else if (WhirlpoolProductManager.REF_KEY_SPECIFICATION_SHEET.equals(referenceKey)) {
							dirPrefix = "/" + WhirlpoolProductManager.DIRECTORY_PREFIX_SPECIFICATION_SHEET + "/";
							docType = "Specification Sheet";
							hasDocument = true;
						}

						String documentUrl = currentSite.getBaseAssetsDir() + currentSite.getString("PRODUCT_DOCS_PATH") + dirPrefix + file.getString("FILE_URL");
						String dcsuri = "/assets/" + currentSite.getString("PRODUCT_DOCS_PATH") + dirPrefix + file.getString("FILE_URL");
						String displayName = file.getString("DISPLAY_NAME");
						String pdfName = (String) product.get("STYLE");
						if (displayName == null || "".equals(displayName)) {
							displayName = file.getString("FILE_URL");
						}
						if (StringUtil.isEmpty(pdfName)) {
							pdfName = categoryName;
						}
						else {
							pdfName += " - " + categoryName;
						}
						displayName += " (" + file.getString("FILE_SIZE") + ")";

						String onclick = "dcsMultiTrack('WT.pn','','WT.pn_sc','','WT.pc','','WT.si_n','','WT.si_p','','DCS.dcsuri','" + dcsuri + "','WT.ti', 'PDF From Product Page','WT.cg_n','PDF From Product Page', 'WT.cg_s', '" + docType + "','DCSext.pdforigin','From Product Page','DCSext.pdftype','" + docType + "','DCSext.pdfname','" + pdfName + "');";
						if(isWarranty){
							isWarranty = false;
							warrantyDisplayName = displayName;
							warrantyOnClick = onclick;
							warrantyDocumentUrl = documentUrl;
						}
						//TSK0030 Modified  by Phuong Ngo Thi Bich on 10/04/07
						if (hasDocument) {
					%>
						<li>
							<span class="icon"></span>
							<html:a href='<%=documentUrl%>' onClick="<%=onclick%>" ><%=displayName%></html:a>
						</li>

					<%
						}
					%>
				</logic:iterator>
			</ul>
		</div>
		
		<div id="warranty">
			<h5>Warranty</h5>
			<p><%=warrantyContent%></p>
			<ul class="guides">
				<li>
					<span class="icon"></span>
					<html:a href='<%=warrantyDocumentUrl%>' onClick='<%=warrantyOnClick %>'><%=warrantyDisplayName%></html:a>
				</li>
			</ul>
		</div>

	</div>
</div>
<% } %>
<!-- END Specifications panel -->

<!-- START Product Literature panel -->
<% if (showLiteratureTab) { %>
<div class="panel" id="panel2" style='display: <%=defaultTab.equals(PANEL2)?"block":"none"%>'>

		<table cellspacing="0" cellpadding="0" id="lit-table">
		<logic:iterator id="file" type="com.fry.ocp.catalog.EntityFile" collection="<%=entityFiles%>">
			<%
				String referenceKey = file.getString("REFERENCE_KEY");
				String dirPrefix = "/";
				String docType = "";
				boolean hasDocument = false;
				if ("USECARE".equals(referenceKey)) {
					dirPrefix = "/" + WhirlpoolProductManager.DIRECTORY_PREFIX_USECARE + "/";
					docType = "Use and Care";
					hasDocument = true;
				} else if ("INSTALLGUIDE".equals(referenceKey)) {
					dirPrefix = "/" + WhirlpoolProductManager.DIRECTORY_PREFIX_INSTALLGUIDE + "/";
					docType = "Installation Instructions";
					hasDocument = true;
				} else if ("ENERGYGUIDE".equals(referenceKey)) {
					dirPrefix = "/" + WhirlpoolProductManager.DIRECTORY_PREFIX_ENERGYGUIDE + "/";
					docType = "Energy Guide";
					hasDocument = true;
				} else if ("DIMENSIONGUIDE".equals(referenceKey)) {
					dirPrefix = "/" + WhirlpoolProductManager.DIRECTORY_PREFIX_DIMENSIONGUIDE + "/";
					docType = "Dimension Guide";
					hasDocument = true;
				}
				// TSK0030 Added by Phuong Ngo Thi Bich on 10/04/07
				else if ("COMMERCIALSPECIFICATIONS".equals(referenceKey)) {
					dirPrefix = "/" + WhirlpoolProductManager.DIRECTORY_PREFIX_COMMERCIALSPECIFICATIONS + "/";
					docType = "Commercial Specifications";
					hasDocument = true;
				}
				// End TSK0030 Added by Phuong Ngo Thi Bich on 10/04/07
				// Start "Show WARRANTY" Added by Chuong Nguyen on 09/09/08
				else if ("WARRANTY".equals(referenceKey)) {
					dirPrefix = "/" + WhirlpoolProductManager.DIRECTORY_PREFIX_WARRANTY + "/";
					docType = "Warranty";
					hasDocument = true;
				}
				// End "Show WARRANTY" Added by Chuong Nguyen on 09/09/08
            //Additional Document Types: Buy Guide, Specification Sheet
            else if (WhirlpoolProductManager.REF_KEY_BUYGUIDE.equals(referenceKey)) {
               dirPrefix = "/" + WhirlpoolProductManager.DIRECTORY_PREFIX_BUYGUIDE + "/";
               docType = "Buy Guide";
               hasDocument = true;
            }
            else if (WhirlpoolProductManager.REF_KEY_SPECIFICATION_SHEET.equals(referenceKey)) {
               dirPrefix = "/" + WhirlpoolProductManager.DIRECTORY_PREFIX_SPECIFICATION_SHEET + "/";
               docType = "Specification Sheet";
               hasDocument = true;
            }

				String documentUrl = currentSite.getBaseAssetsDir() + currentSite.getString("PRODUCT_DOCS_PATH") + dirPrefix + file.getString("FILE_URL");
				String dcsuri = "/assets/" + currentSite.getString("PRODUCT_DOCS_PATH") + dirPrefix + file.getString("FILE_URL");
				String displayName = file.getString("DISPLAY_NAME");
				String pdfName = (String) product.get("STYLE");
				if (displayName == null || "".equals(displayName)) {
					displayName = file.getString("FILE_URL");
				}
				if (StringUtil.isEmpty(pdfName)) {
					pdfName = categoryName;
				}
				else {
					pdfName += " - " + categoryName;
				}
				displayName += " (" + file.getString("FILE_SIZE") + ")";

				String onclick = "dcsMultiTrack('WT.pn','','WT.pn_sc','','WT.pc','','WT.si_n','','WT.si_p','','DCS.dcsuri','" + dcsuri + "','WT.ti', 'PDF From Product Page','WT.cg_n','PDF From Product Page', 'WT.cg_s', '" + docType + "','DCSext.pdforigin','From Product Page','DCSext.pdftype','" + docType + "','DCSext.pdfname','" + pdfName + "');";
				//TSK0030 Modified  by Phuong Ngo Thi Bich on 10/04/07
				if (hasDocument) {
			%>
			<tr>
				<td><html:img src='<%=devBaseImagePath + "/img-pdf-icon.gif"%>' alt="PDF" /></td>
				<td><html:a href='<%=documentUrl%>' onClick="<%=onclick%>" ><%=displayName%></html:a></td>
			</tr>

			<%
				}
			%>
		</logic:iterator>
		</table>

		<dl id="get-reader">
			<dt>
				<html:a href="http://www.adobe.com/products/acrobat/readstep2.html" target="_blank">
					<html:img src='<%=devBaseImagePath + "/img-acrobat-icon.gif"%>' alt='<%=I18NUtil.getString(SiteManager.getLocale(currentSite, request), "product_info.Get_Adobe_Reader", "Get Adobe Reader")%>' />
				</html:a>
			</dt>
			<dd>You may need to install Adobe Acrobat Reader to view these documents.</dd>
		</dl>

</div>
<% } %>
<!-- END Product Literature panel -->



<!-- START Reviews panel -->
<% if (showReviewsTab) { %>
<div class="panel" id="panel5" style='display: <%=defaultTab.equals(PANEL5)?"block":"none"%>;'>
&nbsp;
</div>
<% } %>
<!-- END Description panel -->

<%
	int acsSize = productAccessories.size();
	boolean event = (acsSize % 2 == 0);
	Product prod1;
	Product prod2;
	String productName1;
	String productName2;
	String productModel1;
	String productModel2;
	boolean showMSRP;
	Category relatedCat1;
	Category relatedCat2;
	Category relatedParentCat1 = null;
	Category relatedParentCat2 = null;
	String thumbnailImage1;
	String thumbnailImage2;
	String productUrl1;
	String productUrl2;
	String productMSRP1;
	String productMSRP2;
%>
<!-- START Related Products panel -->
<% if (showRelatedTab) { %>
<div id="relatedProduct" class="section">
<table cellpadding="0" cellspacing="0" border="0" width="100%" style="padding:0 10px;">
<%
	int relatedSize = relatedProducts.size();
	event = (relatedSize % 2 == 0);


	/*
			Check whether or not show MSRP
			*/
	showMSRP = "Y".equals(currentSite.getString("PROD_BROWSE_DISPLAY_MSRP"));
	for (int i = 0; i < relatedSize - 1; i = i + 2) {
		/*
					Get product from Product list
					 */
		prod1 = (Product) relatedProducts.get(i);
		prod2 = (Product) relatedProducts.get(i + 1);
		/*
					Get product name
					 */
		productName1 = prod1.getString("NAME");
		productName2 = prod2.getString("NAME");
		/*
					Get product Model
					 */
		productModel1 = prod1.getString("STYLE");
		productModel2 = prod2.getString("STYLE");

		/*
					Product link point to Product Detail page
					 */
		Category[] categories = CatalogUtils.getCategoriesFromProduct(prod1);
		productUrl1 = SEOUtil.buildProductURL(prod1, categories[2], categories[1], null);
		categories = CatalogUtils.getCategoriesFromProduct(prod2);
		productUrl2 = SEOUtil.buildProductURL(prod2, categories[2], categories[1], null);

		/*
					Get product thumnail image
					 */
		thumbnailImage1 = MultiSiteWebUtil.getThumbnailImage(currentSite, prod1);
		thumbnailImage2 = MultiSiteWebUtil.getThumbnailImage(currentSite, prod2);
		/*
					Get product MSRP
					 */

		productMSRP1 = MultiSiteWebUtil.getProductPrice(prod1);
		productMSRP2 = MultiSiteWebUtil.getProductPrice(prod2);

%>
<tr valign="top">
	<td class="rel-prod-image">
		<html:a href="<%=productUrl1%>">
			<html:img src="<%=thumbnailImage1%>" alt="<%=productName1%>" border="0"/>
		</html:a>
	</td>
	<td>
		<html:a href="<%=productUrl1%>"><b><%=productName1%>
		</b></html:a>
		<br/>
		<i18n:message key="product_info.Model">Model</i18n:message>
		<html:a href="<%=productUrl1%>" styleClass="dark"><%=productModel1%>
		</html:a>
		<br/>
		<logic:if expression="<%=showMSRP%>">
			<i18n:message key="product_compare.MSRP">MSRP*</i18n:message>
			<%=productMSRP1 == null ? "" : productMSRP1%><br />
		</logic:if>
		<html:a href="<%=productUrl1%>" styleClass="view-prod-link">View product</html:a>
	</td>
	<td class="rel-prod-image">
		<html:a href="<%=productUrl2%>">
			<html:img src="<%=thumbnailImage2%>" alt="<%=productName2%>" border="0"/>
		</html:a>
	</td>
	<td>
		<html:a href="<%=productUrl2%>"><b><%=productName2%></b></html:a><br/>
		<i18n:message key="product_info.Model">Model</i18n:message>
		<html:a href="<%=productUrl2%>" styleClass="dark"><%=productModel2%>
		</html:a>
		<br/>
		<logic:if expression="<%=showMSRP%>">
			<i18n:message key="product_compare.MSRP">MSRP*</i18n:message>
			<%=productMSRP2 == null ? "" : productMSRP2%><br />
		</logic:if>
		<html:a href="<%=productUrl2%>" styleClass="view-prod-link">View product</html:a>
	</td>
</tr>
<%
	if (event && i != (relatedSize - 2)) {
%>
<tr>
	<td colspan="4"><br/><br/></td>
</tr>
<%
	}
	if (!event && relatedSize != 1) {
%>
<tr>
	<td colspan="4"><br/><br/></td>
</tr>
<%
		}
	}
%>
<%
	if (!event) {
		/*
			  Get product from Product list
				*/
		prod1 = (Product) relatedProducts.get(relatedSize - 1);
		/*
			  Get product name
				*/
		productName1 = prod1.getString("NAME");
		/*
			  Get product Model
				*/
		productModel1 = prod1.getString("STYLE");

		/*
			  Product link point to Product Detail page
				*/
		Category[] categories = CatalogUtils.getCategoriesFromProduct(prod1);
		productUrl1 = SEOUtil.buildProductURL(prod1, categories[2], categories[1], null);
		/*
			  Get product thumnail image
				*/
		thumbnailImage1 = MultiSiteWebUtil.getThumbnailImage(currentSite, prod1);
		/*
			  Get product MSRP
				*/
		productMSRP1 = MultiSiteWebUtil.getProductPrice(prod1);

%>
<tr valign="top">
	<td width="25%">
		<html:a href="<%=productUrl1%>">
			<html:img src="<%=thumbnailImage1%>" alt="<%=productName1%>" border="0"/>
		</html:a>
	</td>
	<td width="25%">
		<html:a href="<%=productUrl1%>"><b><%=productName1%>
		</b></html:a>
		<br/>
		<i18n:message key="product_info.Model">Model</i18n:message>
		<html:a href="<%=productUrl1%>" styleClass="dark"><%=productModel1%>
		</html:a>
		<br/>
		<logic:if expression="<%=showMSRP%>">
			<i18n:message key="product_compare.MSRP">MSRP*</i18n:message>
			<%=productMSRP1 == null ? "" : productMSRP1%><br/>
		</logic:if>
		<html:a href="<%=productUrl1%>" styleClass="view-prod-link">View product</html:a>
	</td>
	<td>&nbsp;</td>
	<td>&nbsp;</td>
</tr>
<%
	}
%>

</table>
</div>
<% } %>
<!-- END Related Products panel -->



<!-- START Accessories panel -->
<% if (showAccessoriesTab) { %>

<%
	String topRow = "";
	String midRow = "";
	String bottomRow = "";
%>
<div id="accessories" class="section">
	<h2>Parts and Accessories</h2>
	<table border="0" cellspacing="0" cellpadding="0" id="zoomViewProductSlider">
		<tbody>
			<tr>
				<td>
					<div id="mpLeftArrow" class="iconSprite leftArrow mouseout"></div>
				</td>
				<td align="center">
				
					<div align="center" class="sliderView" id="miniProductViewPort">
						<table cellpadding=0 cellspacing=0 border=0>
							
								<%

									showMSRP = "Y".equals(currentSite.getString("PROD_BROWSE_DISPLAY_MSRP"));
								
									for (int i = 0; i < acsSize - 1; i = i + 2) {
										/*
													Get product from Product list
													 */
										prod1 = (Product) productAccessories.get(i);
										prod2 = (Product) productAccessories.get(i + 1);
										/*
													Get product name
													 */
										productName1 = prod1.getString("NAME");
										productName2 = prod2.getString("NAME");
										/*
													Get product Model
													 */
										productModel1 = prod1.getString("STYLE");
										productModel2 = prod2.getString("STYLE");
										/*
													Get category & parent category
													 */
										//prod 1
										try {
											List relatedCats1 = prod1.getCategories(true);
											if (relatedCats1 != null && relatedCats1.size() != 0) {
												relatedCat1 = (Category) relatedCats1.get(0);
											} else {
												relatedCat1 = null;
											}
											Set relatedParentCats1;
											if (relatedCat1 != null) {
												relatedParentCats1 = relatedCat1.getAllParentCategories(true);
												if (relatedParentCats1 != null && relatedParentCats1.size() != 0) {
													relatedParentCat1 = (Category) relatedParentCats1.iterator().next();
												} else {
													relatedParentCat1 = null;
												}
											}
										} catch (Exception ex) {
											relatedCat1 = null;
											relatedParentCat1 = null;
										}
										//prod 2
										try {
											List relatedCats2 = prod2.getCategories(true);
											if (relatedCats2 != null && relatedCats2.size() != 0) {
												relatedCat2 = (Category) relatedCats2.get(0);
											} else {
												relatedCat2 = null;
											}
											Set relatedParentCats2;
											if (relatedCat2 != null) {
												relatedParentCats2 = relatedCat2.getAllParentCategories(true);
												if (relatedParentCats2 != null && relatedParentCats2.size() != 0) {
													relatedParentCat2 = (Category) relatedParentCats2.iterator().next();
												} else {
													relatedParentCat2 = null;
												}
											}
										} catch (Exception ex) {
											relatedCat2 = null;
											relatedParentCat2 = null;
										}
										/*
													Product link point to Product Detail page
													 */
										Category[] accessoryCategories = CatalogUtils.getCategoriesFromProduct(prod1);
										productUrl1 = SEOUtil.buildAccessoryProductURL(prod1, accessoryCategories[1], accessoryCategories[0], "");
										accessoryCategories = CatalogUtils.getCategoriesFromProduct(prod2);
										productUrl2 = SEOUtil.buildAccessoryProductURL(prod2, accessoryCategories[1], accessoryCategories[0], "");
										/*
													Get product thumnail image
													 */
										thumbnailImage1 = MultiSiteWebUtil.getThumbnailImage(currentSite, prod1);
										thumbnailImage2 = MultiSiteWebUtil.getThumbnailImage(currentSite, prod2);
										/*
													Get product MSRP
													 */
										productMSRP1 = MultiSiteWebUtil.getProductPrice(prod1);
										productMSRP2 = MultiSiteWebUtil.getProductPrice(prod2);
								%>
							
									
									
									
								
									<%
									topRow += "<td valign='top'><div><a href='"+productUrl2+"'><img class='miniProductSliderImg' src='"+thumbnailImage2+"' alt='"+productName2+"' border=0></a></div></td>";
									midRow += "<td valign='top'><div><a href='"+productUrl2+"' class='prodName'>"+productName2+"</a></div></td>";
									
									if(showMSRP){
									
										bottomRow += "<td><div><p class='acc-price'>"+productMSRP2+"</p></div></td>";
									} else {
										bottomRow += "<td>&nbsp;</td>";
									}
									
									/**
									topRow += '<td><div><a href="'+productUrl2+'"><img src="'+thumbnailImage2+'" alt="'+productName2+'" border=0/></a></td>';
									
									midRow += '<td><a href="'+productUrl2+'" class="prodNam">"'+productName2+'"</a></td>';
									
									if(showMSRP){
									
										bottomRow += '<td><p class="acc-price">"'+productUrl2+'"</p></td>';
									} else {
										bottomRow += '<td>&nbsp;</td>';
									}
									**/
									%>
								<%--	
								<td>	
									<div>
										<html:a href="<%=productUrl2%>">
											<html:img src="<%=thumbnailImage2%>" alt="<%=productName2%>" border="0"/>
										</html:a>
										<html:a styleClass="prodName" href="<%=productUrl2%>"><%=productName2%></html:a>
									</div>
									<p class="acc-price">
										<logic:if expression="<%=showMSRP%>">
											<%=productMSRP2 == null ? "" : productMSRP2%>
										</logic:if>
									</p>
								</td>
								
								--%>
								<% } %>
								
							<tr><%=topRow%></tr>
							<tr><%=midRow%></tr>
							<tr><%=bottomRow%></tr>
							
						</table>
						
					</div>
				</td>
				<td>
					<div id="mpRightArrow" class="iconSprite rightArrow  mouseout"></div>
				</td>
			</tr>
		</tbody>
	</table>
</div>


<% } %>
<script type="text/javascript">
	binder.extend();
document.ready
	binder.group_arrows_simpleXslider.create(
		"group_arrows_simpleXslider",
		{}
	);
</script>
<!-- END Accessories panel -->


<!-- START Product Videos panel -->
<% if (showVideosTab) { %>

<style>

#pdp_Wrapper #pop-outs li #vid {
	display:block;
}
</style>

<%--
<div class="panel" id="panel7" style='display: <%=defaultTab.equals(PANEL7)?"block":"none"%>'>

		<table cellspacing="0" cellpadding="0" id="lit-table">
		<logic:iterator id="fileVideos" type="com.fry.ocp.catalog.EntityFile" collection="<%=entityFiles%>">
			<%
				String referenceKey = fileVideos.getString("REFERENCE_KEY");
				String fileUrl = currentSite.getBaseAssetsDir() + currentSite.getString("VIDEOS_DIR") + fileVideos.getString("FILE_URL");
				String displayName = fileVideos.getString("DISPLAY_NAME");
				boolean hasFile = false;
				if (WhirlpoolProductManager.REF_KEY_VIDEO.equals(referenceKey)) {
					hasFile = true;
				}

				if (displayName == null || "".equals(displayName)) {
					displayName = fileVideos.getString("FILE_URL");
				}

				if (hasFile) {
			%>
					<tr>
						<td><html:a href='<%=fileUrl%>' target="_blank"><%=displayName%></html:a></td>
					</tr>
			<%
				}
			%>
		</logic:iterator>
		</table>
</div>

--%>
<% } %>
<!-- END Product Videos panel -->

</div>
<!-- END "pdp_Wrapper" div from product_amana_body.jsp panel -->

<%
	{
		java.util.LinkedHashMap tmp = new java.util.LinkedHashMap();

		tmp.put("panel1", "document.featuresImage");
		tmp.put("panel2", "document.litImage");
		tmp.put("panel3", "document.accImage");
		tmp.put("panel4", "document.relatedImage");
		tmp.put("panel5", "document.descImage");
		tmp.put("panel6", "document.specsImage");
		tmp.put("panel7", "document.videosImage");

%>
<script type="text/javascript" language="JavaScript">
	activeTab = <%=tmp.get(defaultTab)%>;
</script>
<%
	}
%>
<!-- WebTrends Implemetation -->

<meta name="WT.ti" content="<%=MultiSiteWebUtil.replaceHtmlCharacters(pageTitle)%>"/>
<meta name="WT.cg_n" content="Product Categories;<%=parentCategoryName%>;Product Details;<%=categoryName%>"/>
<meta name="WT.cg_s" content="<%=parentCategoryName%>;<%=categoryName%>;Description;Description"/>
<meta name="WT.pn" content="<%=productModel%> - <%=productName%>"/>
<meta name="WT.pn_sc" content="<%=categoryName%>"/>
<meta name="WT.pc" content="<%=parentCategoryName%>"/>
<meta id="WT.tx_e" name="WT.tx_e" content="v"/>
<meta name="WT.tx_u" content="1"/>
<meta name="WT.si_n" content="Checkout"/>
<meta name="WT.si_p" content="ProdView"/>
<%
	String keywordString = request.getParameter("keyword");
	if (!StringUtil.isEmpty(keywordString)) {
		keywordString = MultiSiteWebUtil.replaceHtmlCharacters(keywordString);
%>
<meta name="WT.oss" content="<%=keywordString%>"/>
<meta name="WT.oss_r" content="1"/>
<%
	}
}
%>
