import argparse
import io
import json
import xml.etree.ElementTree as ET

class GenerateService:
  """ Generate a service API XML description from a JSON descriptor such
      as those at:

      https://github.com/aws/aws-sdk-cpp/tree/master/code-generation/api-descriptions

      example:

      wget https://raw.githubusercontent.com/aws/aws-sdk-cpp/master/code-generation/api-descriptions/rds-2014-10-31.normal.json
      python generate-service.py -d rds-2014-10-31.normal.json | xmllint --format - > rds-service-metadata.xml
  """

  @classmethod
  def populate(cls, sm_ele, sm_dict):
    for key in sorted(sm_dict):
      value = sm_dict.get(key)
      if isinstance(value, dict):
        smSubEle = ET.SubElement(sm_ele, key)
        cls.populate(smSubEle, value)
      elif isinstance(value, list):
        smSubConEle = ET.SubElement(sm_ele, key + '-collection')
        for subValue in value:
          smSubEle = ET.SubElement(smSubConEle, key)
          if isinstance(subValue, dict):
            cls.populate(smSubEle, subValue)
          else:
            smSubEle.set('value', unicode(subValue))
      else:
        sm_ele.set(key, unicode(value))

  @classmethod
  def main(cls):
    parser = argparse.ArgumentParser()
    parser.add_argument("-d", "--description", required=True,
                        help="JSON service API description")
    args = parser.parse_args()
    with io.open(args.description) as file:
      sm_dict = json.load(file)
      sm_dom = ET.Element('service-metadata')
      cls.populate(sm_dom, sm_dict)
      ET.dump(sm_dom)

if __name__ == "__main__":
  GenerateService.main()

