function finish_model(mdl, file, noteText, notePos)
%FINISH_MODEL  Add a note, compile once (catches wiring errors) and save.
if nargin > 2 && ~isempty(noteText)
    try
        note = Simulink.Annotation([mdl '/' strrep(noteText, '/', '//')]);
        note.Position = notePos;
        note.FontSize = 11;
    catch err
        warning('finish_model:note', 'Note not added: %s', err.message);
    end
end
set_param(mdl, 'SimulationCommand', 'update');
save_system(mdl, file);
close_system(mdl, 0);
fprintf('  built %s\n', file);
end
