
package states;

import flixel.addons.ui.FlxInputText;
import flixel.ui.FlxButton;
import haxe.io.Path;
import sys.FileSystem;
import sys.io.File;

class FFIEditorState extends MusicBeatState
{
    var modFolder:String;
    var rootPath:String;
    var currentPath:String;
    var currentFile:String = null;

    var entries:Array<String> = [];
    var selected:Int = 0;

    var pathText:FlxText;
    var statusText:FlxText;
    var fileList:FlxTypedGroup<FlxText>;
    var editor:FlxInputText;
    var nameInput:FlxInputText;

    public function new(modFolder:String)
    {
        this.modFolder = modFolder;
        super();
    }

    override function create()
    {
        super.create();

        persistentUpdate = true;
        FlxG.mouse.visible = true;

        rootPath = Paths.mods(modFolder);
        currentPath = rootPath;

        var bg = new FlxSprite().makeGraphic(
            FlxG.width, FlxG.height, 0xFF20202A
        );
        add(bg);

        var title = new FlxText(
            20, 12, FlxG.width - 40,
            'FFI EDITOR - $modFolder', 24
        );
        title.setFormat(Paths.font('vcr.ttf'), 24, FlxColor.WHITE);
        add(title);

        pathText = new FlxText(20, 48, 340, '', 14);
        pathText.setFormat(Paths.font('vcr.ttf'), 14, FlxColor.CYAN);
        add(pathText);

        fileList = new FlxTypedGroup<FlxText>();
        add(fileList);

        editor = new FlxInputText(
            380, 112, FlxG.width - 400, '',
            16, FlxColor.WHITE, FlxColor.BLACK
        );
        editor.lines = 25;
        editor.wordWrap = true;
        editor.fieldHeight = FlxG.height - 160;
        editor.visible = false;
        add(editor);
        nameInput = new FlxInputText(
            20, FlxG.height - 65, 250, '',
            16, FlxColor.WHITE, FlxColor.BLACK
        );
        nameInput.visible = true;
        add(nameInput);

        add(new FlxButton(20, 76, 'OPEN', openSelected));

        add(new FlxButton(110, 76, 'NEW TXT', function() createFile('txt')));
        add(new FlxButton(200, 76, 'NEW LUA', function() createFile('lua')));
        add(new FlxButton(290, 76, 'NEW JSON', function() createFile('json')));
        add(new FlxButton(380, 76, 'NEW XML', function() createFile('xml')));

        add(new FlxButton(490, 76, 'SAVE', saveCurrentFile));
        add(new FlxButton(580, 76, 'CLOSE FILE', closeCurrentFile));
        add(new FlxButton(810, 76, 'RENAME', renameSelected));
        add(new FlxButton(FlxG.width - 110, 12, 'BACK', goBack));
        add(new FlxButton(700, 76, 'NEW FOLDER', createFolder));

        statusText = new FlxText(
            20, FlxG.height - 30, FlxG.width - 40, '', 14
        );
        statusText.setFormat(Paths.font('vcr.ttf'), 14, FlxColor.WHITE);
        add(statusText);

        refreshDirectory();
        addTouchPad('UP_DOWN', 'A_B_C');
    }

    function refreshDirectory()
    {
        entries = [];
        fileList.clear();
        selected = 0;

        try
        {
            if (currentPath != rootPath)
                entries.push('..');

            var names = FileSystem.readDirectory(currentPath);
            var folders:Array<String> = [];
            var files:Array<String> = [];

            for (name in names)
            {
                var fullPath = Path.join([currentPath, name]);

                if (FileSystem.isDirectory(fullPath))
                    folders.push(name + '/');
                else
                    files.push(name);
            }

            folders.sort(Reflect.compare);
            files.sort(Reflect.compare);

            entries = entries.concat(folders);
            entries = entries.concat(files);

            for (i in 0...entries.length)
            {
                var item = new FlxText(
                    24, 112 + i * 28, 330, entries[i], 18
                );

                item.setFormat(
                    Paths.font('vcr.ttf'), 18, FlxColor.WHITE
                );

                fileList.add(item);
            }

            statusText.text = entries.length == 0
                ? 'This folder is empty.'
                : 'Select an entry, then press OPEN.';
        }
        catch (e:Dynamic)
        {
            statusText.text = 'Could not read folder: $e';
        }

        pathText.text = currentPath.substr(rootPath.length);
        updateSelection();
    }

    function updateSelection()
    {
        for (i in 0...fileList.members.length)
        {
            var item = fileList.members[i];

            if (item != null)
                item.color = (i == selected)
                    ? FlxColor.YELLOW
                    : FlxColor.WHITE;
        }
    }

    function openSelected()
    {
        if (entries.length == 0)
            return;

        if (selected < 0 || selected >= entries.length)
            return;

        var name = entries[selected];

        if (name == '..')
        {
            currentPath = Path.directory(currentPath);
            refreshDirectory();
            return;
        }

        var isFolder = StringTools.endsWith(name, '/');
        var cleanName = isFolder
            ? name.substr(0, name.length - 1)
            : name;

        var fullPath = Path.join([currentPath, cleanName]);

        if (isFolder)
        {
            currentPath = fullPath;
            refreshDirectory();
        }
        else if (['txt', 'lua', 'json', 'xml', 'hx'].contains(
            Path.extension(cleanName).toLowerCase()
        ))
        {
            try
            {
                currentFile = fullPath;
                editor.text = File.getContent(fullPath);
                editor.visible = true;
                statusText.text = 'Editing $cleanName.';
            }
            catch (e:Dynamic)
            {
                statusText.text = 'Could not open file: $e';
            }
        }
        else
        {
            statusText.text = 'Unsupported file type.';
        }
    }

    function createFile(extension:String)
        {
            var name = 'new_file.' + extension;
            var number = 1;
        
            while (FileSystem.exists(Path.join([currentPath, name])))
            {
                name = 'new_file_$number.' + extension;
                number++;
            }
        
            var fullPath = Path.join([currentPath, name]);
        
            try
            {
                var initialContent = '';

                if (extension == 'lua')
                {
                    initialContent =
                        'function onCreate()\n' +
                        '    debugPrint("Lua script loaded!")\n' +
                        'end\n\n' +
                        'function onUpdate(elapsed)\n' +
                        '    -- Runs every frame.\n' +
                        'end\n\n' +
                        'function onBeatHit()\n' +
                        '    -- Runs on every beat.\n' +
                        'end\n';
                
                }
                
                File.saveContent(fullPath, initialContent);
                refreshDirectory();
        
                currentFile = fullPath;
                editor.text = initialContent;
                editor.visible = true;
        
                statusText.text = 'Created $name.';
            }
            catch (e:Dynamic)
            {
                statusText.text = 'Could not create file: $e';
            }
        }

    function createFolder()
        {
            var name = 'new_folder';
            var number = 1;
        
            while (FileSystem.exists(Path.join([currentPath, name])))
            {
                name = 'new_folder_$number';
                number++;
            }
        
            var fullPath = Path.join([currentPath, name]);
        
            try
            {
                FileSystem.createDirectory(fullPath);
                refreshDirectory();
                statusText.text = 'Created folder $name.';
            }
            catch (e:Dynamic)
            {
                statusText.text = 'Could not create folder: $e';
            }
        }

    function renameSelected()
        {
            if (entries.length == 0 || selected < 0 || selected >= entries.length)
                return;
        
            var oldName = entries[selected];
        
            if (oldName == '..')
            {
                statusText.text = 'Cannot rename the parent folder.';
                return;
            }
        
            var newName = StringTools.trim(nameInput.text);
        
            if (newName == '' || newName == '.' || newName == '..'
                || newName.indexOf('/') != -1 || newName.indexOf('\\') != -1)
            {
                statusText.text = 'Enter a valid name.';
                return;
            }
        
            var isFolder = StringTools.endsWith(oldName, '/');
            var cleanOldName = isFolder
                ? oldName.substr(0, oldName.length - 1)
                : oldName;
        
            var oldPath = Path.join([currentPath, cleanOldName]);
            var newPath = Path.join([currentPath, newName]);
        
            if (FileSystem.exists(newPath))
            {
                statusText.text = 'That name already exists.';
                return;
            }
        
            try
            {
                FileSystem.rename(oldPath, newPath);
        
                if (currentFile == oldPath)
                    currentFile = newPath;
        
                nameInput.text = '';
                refreshDirectory();
                statusText.text = 'Renamed to $newName.';
            }
            catch (e:Dynamic)
            {
                statusText.text = 'Could not rename: $e';
            }
        }

    function saveCurrentFile()
        {
            if (currentFile == null)
                return;

            var extension = Path.extension(currentFile).toLowerCase();

            if (extension == 'json')
            {
                try
                {
                    haxe.Json.parse(editor.text);
                }
                catch (e:Dynamic)
                {
                    statusText.text = 'Invalid JSON: $e';
                    return;
                }
            }

            try
            {
                File.saveContent(currentFile, editor.text);
                statusText.text = 'Saved ' + Path.withoutDirectory(currentFile);
            }
            catch (e:Dynamic)
            {
                statusText.text = 'Could not save file: $e';
            }
        }

    function closeCurrentFile()
    {
        currentFile = null;
        editor.visible = false;
        statusText.text = 'File closed.';
    }

    function goBack()
    {
        if (currentFile != null)
        {
            closeCurrentFile();
            return;
        }

        MusicBeatState.switchState(new ModsMenuState(modFolder));
    }

    override function update(elapsed:Float)
    {
        if (currentFile == null && entries.length > 0)
        {
            if (controls.UI_UP_P)
            {
                selected = (selected - 1 + entries.length) % entries.length;
                updateSelection();
            }
            else if (controls.UI_DOWN_P)
            {
                selected = (selected + 1) % entries.length;
                updateSelection();
            }

            if (controls.ACCEPT)
                openSelected();

            if (controls.BACK)
                goBack();
        }

        if (FlxG.mouse.justPressed)
        {
            for (i in 0...fileList.members.length)
            {
                var item = fileList.members[i];

                if (item != null && FlxG.mouse.overlaps(item))
                {
                    selected = i;
                    updateSelection();
                    break;
                }
            }
        }

        super.update(elapsed);
    }

    override function destroy()
    {
        if (editor != null)
            editor.destroy();

        super.destroy();
    }
}
