import yaml

def add_shape_property(dashboard_file):
    with open(dashboard_file, 'r') as f:
        dashboard_data = yaml.safe_load(f)

    for view in dashboard_data.get('views', []):
        for section in view.get('sections', []):
            if 'items' in section:
                for item in section['items']:
                    if 'shape' not in item:
                        item['shape'] = 'rectangle'
            if 'sections' in section:
                for subsection in section['sections']:
                    if 'items' in subsection:
                        for item in subsection['items']:
                            if 'shape' not in item:
                                item['shape'] = 'rectangle'

    with open(dashboard_file, 'w') as f:
        yaml.dump(dashboard_data, f, indent=2)

if __name__ == "__main__":
    add_shape_property('data/dashboard.yaml')