enum BusinessCategory {
  generalBusiness('General Business'),
  clothingFashion('Clothing / Fashion'),
  groceryKirana('Grocery / Kirana'),
  electronics('Electronics'),
  furniture('Furniture'),
  hardware('Hardware'),
  jewellery('Jewellery'),
  beautySalon('Beauty / Salon'),
  medicalPharmacy('Medical / Pharmacy'),
  foodRestaurant('Food / Restaurant'),
  printingStationery('Printing / Stationery'),
  constructionSupplier('Construction / Material Supplier'),
  professionalServices('Freelancer / Professional Services'),
  repairService('Repair / Service Business'),
  other('Other');

  const BusinessCategory(this.label);
  final String label;
}

class ProductFieldDefinition {
  const ProductFieldDefinition(this.key, this.label, {this.number = false});
  final String key;
  final String label;
  final bool number;
}

class BusinessCategoryPreset {
  const BusinessCategoryPreset({
    required this.enabledFields,
    required this.recommendedUnits,
  });
  final Set<String> enabledFields;
  final List<String> recommendedUnits;
}

abstract final class ProductFieldPresets {
  static const fields = <ProductFieldDefinition>[
    ProductFieldDefinition('description', 'Description'),
    ProductFieldDefinition('unit', 'Unit'),
    ProductFieldDefinition('tax', 'Tax'),
    ProductFieldDefinition('hsnSac', 'HSN/SAC'),
    ProductFieldDefinition('sku', 'SKU / Code'),
    ProductFieldDefinition('brand', 'Brand'),
    ProductFieldDefinition('color', 'Color'),
    ProductFieldDefinition('size', 'Size'),
    ProductFieldDefinition('material', 'Material'),
    ProductFieldDefinition('shape', 'Shape'),
    ProductFieldDefinition('weight', 'Weight'),
    ProductFieldDefinition('dimensions', 'Dimensions'),
    ProductFieldDefinition('modelNumber', 'Model Number'),
    ProductFieldDefinition('serialNumber', 'Serial Number'),
    ProductFieldDefinition('batchNumber', 'Batch Number'),
    ProductFieldDefinition('manufacturingDate', 'Manufacturing Date'),
    ProductFieldDefinition('expiryDate', 'Expiry Date'),
    ProductFieldDefinition('quantityLabel', 'Quantity Label'),
    ProductFieldDefinition('variant', 'Variant'),
  ];

  static const _baseUnits = ['pcs', 'box', 'set', 'pair'];
  static const presets = <BusinessCategory, BusinessCategoryPreset>{
    BusinessCategory.generalBusiness: BusinessCategoryPreset(
      enabledFields: {'description', 'unit', 'sku', 'tax', 'hsnSac'},
      recommendedUnits: _baseUnits,
    ),
    BusinessCategory.clothingFashion: BusinessCategoryPreset(
      enabledFields: {'unit', 'size', 'color', 'brand', 'sku', 'tax', 'hsnSac'},
      recommendedUnits: ['pcs', 'set', 'pair'],
    ),
    BusinessCategory.groceryKirana: BusinessCategoryPreset(
      enabledFields: {'unit', 'weight', 'brand', 'sku', 'tax', 'hsnSac'},
      recommendedUnits: [
        'pcs',
        'kg',
        'g',
        'ltr',
        'ml',
        'packet',
        'box',
        'dozen',
      ],
    ),
    BusinessCategory.electronics: BusinessCategoryPreset(
      enabledFields: {'brand', 'modelNumber', 'sku', 'tax', 'hsnSac'},
      recommendedUnits: ['pcs', 'set'],
    ),
    BusinessCategory.furniture: BusinessCategoryPreset(
      enabledFields: {
        'unit',
        'material',
        'dimensions',
        'color',
        'tax',
        'hsnSac',
      },
      recommendedUnits: ['pcs', 'set', 'sq ft', 'feet', 'inch'],
    ),
    BusinessCategory.hardware: BusinessCategoryPreset(
      enabledFields: {'unit', 'size', 'material', 'brand', 'tax', 'hsnSac'},
      recommendedUnits: ['pcs', 'box', 'set', 'kg', 'meter', 'feet', 'inch'],
    ),
    BusinessCategory.jewellery: BusinessCategoryPreset(
      enabledFields: {'weight', 'material', 'color', 'sku', 'tax', 'hsnSac'},
      recommendedUnits: ['pcs', 'pair', 'g'],
    ),
    BusinessCategory.beautySalon: BusinessCategoryPreset(
      enabledFields: {'brand', 'size', 'unit', 'tax', 'description'},
      recommendedUnits: ['pcs', 'ml', 'g', 'service', 'hour'],
    ),
    BusinessCategory.medicalPharmacy: BusinessCategoryPreset(
      enabledFields: {
        'unit',
        'sku',
        'batchNumber',
        'expiryDate',
        'tax',
        'hsnSac',
      },
      recommendedUnits: ['pcs', 'box', 'packet', 'ml', 'g'],
    ),
    BusinessCategory.foodRestaurant: BusinessCategoryPreset(
      enabledFields: {'unit', 'variant', 'tax'},
      recommendedUnits: ['pcs', 'plate', 'portion', 'ml', 'ltr'],
    ),
    BusinessCategory.printingStationery: BusinessCategoryPreset(
      enabledFields: {'unit', 'size', 'color', 'material', 'tax', 'hsnSac'},
      recommendedUnits: ['pcs', 'box', 'set', 'sheet', 'sq ft'],
    ),
    BusinessCategory.constructionSupplier: BusinessCategoryPreset(
      enabledFields: {
        'unit',
        'material',
        'size',
        'weight',
        'dimensions',
        'tax',
        'hsnSac',
      },
      recommendedUnits: ['pcs', 'kg', 'meter', 'feet', 'sq ft', 'sq m'],
    ),
    BusinessCategory.professionalServices: BusinessCategoryPreset(
      enabledFields: {'unit', 'description', 'tax', 'hsnSac'},
      recommendedUnits: ['service', 'hour', 'day', 'project', 'month'],
    ),
    BusinessCategory.repairService: BusinessCategoryPreset(
      enabledFields: {'unit', 'description', 'tax', 'hsnSac'},
      recommendedUnits: ['service', 'hour', 'day', 'project'],
    ),
    BusinessCategory.other: BusinessCategoryPreset(
      enabledFields: {'description', 'unit', 'sku', 'tax', 'hsnSac'},
      recommendedUnits: _baseUnits,
    ),
  };
}
