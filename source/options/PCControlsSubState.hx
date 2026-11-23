package options;

import options.BaseOptionsMenu;
import options.Option;

class PCControlsSubState extends BaseOptionsMenu
{
    public function new()
    {
        title = 'PC Controls';
        rpcTitle = 'PC Controls Menu';

        var option = new Option(
            'Enable PC Controls',
            'Disables mobile touch controls and uses keyboard controls.',
            'pcControls',
            BOOL
        );
        addOption(option);

        super();
    }
}
