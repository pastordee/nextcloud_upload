import 'package:xml/xml.dart' as xml;

/// Utility functions for robust XML parsing
class XmlUtils {
  /// Safely parse XML string with better error handling and diagnostics
  static xml.XmlDocument safeParseXml(String xmlStr, {String? context}) {
    try {
      xmlStr = xmlStr.trim();
      if (xmlStr.isEmpty) {
        throw Exception('Empty XML response received${context != null ? ' in $context' : ''}');
      }

      if (xmlStr.toLowerCase().startsWith('<html') ||
          xmlStr.toLowerCase().startsWith('<!doctype html')) {
        throw Exception('Received HTML response instead of XML${context != null ? ' in $context' : ''}');
      }

      final xmlDeclarationCount = '<?xml'.allMatches(xmlStr).length;
      if (xmlDeclarationCount > 1) {
        throw Exception('Multiple XML declarations found${context != null ? ' in $context' : ''}');
      }

      if (!xmlStr.startsWith('<?xml') && !xmlStr.startsWith('<')) {
        final firstBracket = xmlStr.indexOf('<');
        if (firstBracket > 0) {
          xmlStr = xmlStr.substring(firstBracket);
        } else {
          throw Exception('No valid XML tags found${context != null ? ' in $context' : ''}');
        }
      }

      return xml.XmlDocument.parse(xmlStr);
    } catch (e) {
      rethrow;
    }
  }

  /// Find a single element by name
  static xml.XmlElement findSingleElement(xml.XmlDocument document, String elementName, {String? context}) {
    final elements = document.findAllElements(elementName);
    if (elements.isEmpty) {
      throw Exception('No <$elementName> element found${context != null ? ' in $context' : ''}');
    }
    if (elements.length > 1) {
      throw Exception('Multiple <$elementName> elements found, expected single${context != null ? ' in $context' : ''}');
    }
    return elements.single;
  }
}
