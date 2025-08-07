function [qraw]=qraw_parser(Qpathname)
%QRAW_PARSER_OCTAVE_COMPATIBLE Fully Octave-compatible QSPICE parser
%   Uses cell arrays and structures instead of table() function

% Check Qpath format
if ~isstruct(Qpathname)
    Qpath.qraw = Qpathname;
else
    Qpath = Qpathname;
end

% Read header and determine format
qraw.pathname = Qpath.qraw;
fid = fopen(qraw.pathname, 'rb');
if fid == -1
    error('Cannot open file: %s', qraw.pathname);
end

idx = 1;
qraw.info = {};
while true
    line = fgetl(fid);
    if line == -1
        break;
    end

    line = strtrim(line);
    if isempty(line)
        continue;
    end

    qraw.info{idx} = line;
    idx = idx + 1;

    if strcmp(line, 'Binary:')
        qraw.format = 'binary';
        break;
    elseif strcmp(line, 'Values:')
        qraw.format = 'ascii';
        break;
    end
end

% Determine data flags
qraw.flags = 'real';
for i = 1:length(qraw.info)
    if strncmp(qraw.info{i}, 'Flags: complex', 14)
        qraw.flags = 'complex';
        break;
    end
end

fprintf('Format: %s, Flags: %s\n', qraw.format, qraw.flags);

% Extract parameters from header
qraw.parameters = struct();
qraw.param_names = {};
qraw.param_values = {};
param_count = 0;

for i = 1:length(qraw.info)
    line = qraw.info{i};
    if strncmp(line, '.param ', 7)
        % Parse .param line: .param NAME=VALUE
        param_part = line(8:end);  % Remove '.param '
        eq_pos = strfind(param_part, '=');
        if ~isempty(eq_pos)
            param_count = param_count + 1;
            param_name = strtrim(param_part(1:eq_pos(1)-1));
            param_value_str = strtrim(param_part(eq_pos(1)+1:end));

            % Try to convert to number, keep as string if not possible
            param_value_num = str2double(param_value_str);
            if ~isnan(param_value_num)
                param_value = param_value_num;
            else
                param_value = param_value_str;
            end

            qraw.parameters.(param_name) = param_value;
            qraw.param_names{param_count} = param_name;
            qraw.param_values{param_count} = param_value;
            fprintf('Parameter: %s = %s\n', param_name, num2str(param_value));
        end
    end
end

% Extract aliases from header
qraw.aliases = struct();
qraw.alias_names = {};
qraw.alias_expressions = {};
alias_count = 0;

for i = 1:length(qraw.info)
    line = qraw.info{i};
    if strncmp(line, '.alias ', 7)
        % Parse .alias line: .alias NAME EXPRESSION
        alias_part = line(8:end);  % Remove '.alias '
        space_pos = strfind(alias_part, ' ');
        if ~isempty(space_pos)
            alias_count = alias_count + 1;
            alias_name = strtrim(alias_part(1:space_pos(1)-1));
            alias_expr = strtrim(alias_part(space_pos(1)+1:end));

            qraw.aliases.(alias_name) = alias_expr;
            qraw.alias_names{alias_count} = alias_name;
            qraw.alias_expressions{alias_count} = alias_expr;
            fprintf('Alias: %s = %s\n', alias_name, alias_expr);
        end
    end
end

% Parse variables from header
variables_start = 0;
for i = 1:length(qraw.info)
    if strcmp(qraw.info{i}, 'Variables:')
        variables_start = i;
        break;
    end
end

if variables_start == 0
    error('Variables section not found');
end

% Extract variable information
qraw.id = [];
qraw.expr = {};
qraw.measure = {};
var_count = 0;

for i = variables_start+1:length(qraw.info)
    line = qraw.info{i};
    parts = strsplit(line, '\t');
    if length(parts) >= 3
        var_count = var_count + 1;
        qraw.id(var_count) = str2double(parts{1}) + 1;
        qraw.expr{var_count} = strtrim(parts{2});
        qraw.measure{var_count} = strtrim(parts{3});
    end
end

fprintf('Found %d variables\n', var_count);
for i = 1:var_count
    fprintf('  %d: %s (%s)\n', qraw.id(i), qraw.expr{i}, qraw.measure{i});
end

% Get expected number of points
expected_points = 0;
for i = 1:length(qraw.info)
    if strncmp(qraw.info{i}, 'No. Points:', 11)
        line = qraw.info{i};
        matches = regexp(line, 'No\. Points:\s*(\d+)', 'tokens');
        if ~isempty(matches)
            expected_points = str2double(matches{1}{1});
            break;
        end
    end
end

fprintf('Expected points: %d\n', expected_points);

% Read binary data
if strcmp(qraw.format, 'binary')
    header_end_pos = ftell(fid);
    fseek(fid, 0, 'eof');
    file_end_pos = ftell(fid);
    data_bytes_available = file_end_pos - header_end_pos;

    fseek(fid, header_end_pos, 'bof');

    while true
        pos = ftell(fid);
        byte_val = fread(fid, 1, 'uint8');
        if isempty(byte_val)
            break;
        end
        if byte_val ~= 10 && byte_val ~= 13
            fseek(fid, pos, 'bof');
            break;
        end
    end

    data_start_pos = ftell(fid);
    remaining_bytes = file_end_pos - data_start_pos;
    max_float64_values = floor(remaining_bytes / 8);

    try
        qraw.value64 = fread(fid, max_float64_values, 'float64');
    catch
        try
            fseek(fid, data_start_pos, 'bof');
            qraw.value64 = fread(fid, max_float64_values, 'double');
        catch
            fseek(fid, data_start_pos, 'bof');
            raw_bytes = fread(fid, remaining_bytes, 'uint8');
            num_doubles = floor(length(raw_bytes) / 8);
            qraw.value64 = typecast(uint8(raw_bytes(1:num_doubles*8)), 'double');
        end
    end

elseif strcmp(qraw.format, 'ascii')
    error('ASCII format not supported');
end

fclose(fid);

% Calculate expected data size and reshape
if strcmp(qraw.flags, 'real')
    expected_total_values = expected_points * var_count;
    datacolumn = var_count;
elseif strcmp(qraw.flags, 'complex')
    expected_total_values = expected_points * (1 + (var_count-1)*2);
    datacolumn = 1 + (var_count-1)*2;
end

% Handle size mismatches
if length(qraw.value64) ~= expected_total_values
    if abs(length(qraw.value64) - expected_total_values) <= datacolumn
        if length(qraw.value64) < expected_total_values
            padding_needed = expected_total_values - length(qraw.value64);
            qraw.value64(end+1:end+padding_needed) = 0;
        else
            excess = length(qraw.value64) - expected_total_values;
            qraw.value64 = qraw.value64(1:expected_total_values);
        end
    else
        complete_rows = floor(length(qraw.value64) / datacolumn);
        qraw.value64 = qraw.value64(1:complete_rows * datacolumn);
    end
end

% Perform reshape
if strcmp(qraw.flags, 'real')
    qraw.data = reshape(qraw.value64, datacolumn, [])';
elseif strcmp(qraw.flags, 'complex')
    temp_data = reshape(qraw.value64, datacolumn, [])';
    qraw.data = zeros(size(temp_data,1), var_count);
    qraw.data(:,1) = temp_data(:,1);
    for idx = 2:var_count
        real_col = (idx-1)*2;
        imag_col = (idx-1)*2 + 1;
        qraw.data(:,idx) = temp_data(:,real_col) + 1j*temp_data(:,imag_col);
    end
end

% Create enhanced variable access
qraw.var = struct();
for i = 1:length(qraw.expr)
    % Clean variable name for struct field (remove special characters)
    clean_name = regexprep(qraw.expr{i}, '[^a-zA-Z0-9_]', '_');
    clean_name = regexprep(clean_name, '^(\d)', 'var_$1'); % Prefix if starts with number
    qraw.var.(clean_name) = qraw.data(:,i);
end

% Add computed alias variables
for i = 1:length(qraw.alias_names)
    alias_name = qraw.alias_names{i};
    alias_expr = qraw.alias_expressions{i};

    try
        % Try to evaluate simple aliases
        if strcmp(alias_name, 'Freq') && strcmp(alias_expr, 'Frequency')
            % Direct reference to frequency
            freq_idx = find(strcmp(qraw.expr, 'Frequency'));
            if ~isempty(freq_idx)
                qraw.var.Freq = qraw.data(:,freq_idx);
                fprintf('Added alias variable: Freq\n');
            end
        elseif strcmp(alias_name, 'Omega') && strcmp(alias_expr, '(2*pi*Frequency)')
            % Omega = 2*pi*Frequency
            freq_idx = find(strcmp(qraw.expr, 'Frequency'));
            if ~isempty(freq_idx)
                qraw.var.Omega = 2*pi*qraw.data(:,freq_idx);
                fprintf('Added alias variable: Omega\n');
            end
        elseif contains(alias_expr, 'V(out,0)') && contains(alias_expr, '1mho')
            % I(R1) = 1mho*V(out,0)
            vout_idx = find(strcmp(qraw.expr, 'V(out)'));
            if ~isempty(vout_idx)
                qraw.var.I_R1_ = 1e-3 * qraw.data(:,vout_idx); % 1mho = 1mS
                fprintf('Added alias variable: I_R1_\n');
            end
        else
            fprintf('Alias %s = %s (not automatically computed)\n', alias_name, alias_expr);
        end
    catch
        fprintf('Could not compute alias: %s = %s\n', alias_name, alias_expr);
    end
end

% Create parameter summary (cell array instead of table)
if param_count > 0
    qraw.param_summary = cell(param_count + 1, 2);
    qraw.param_summary{1,1} = 'Parameter';
    qraw.param_summary{1,2} = 'Value';
    for i = 1:param_count
        qraw.param_summary{i+1,1} = qraw.param_names{i};
        qraw.param_summary{i+1,2} = qraw.param_values{i};
    end
    fprintf('\nParameter summary created with %d parameters\n', param_count);
end

% Create alias summary (cell array instead of table)
if alias_count > 0
    qraw.alias_summary = cell(alias_count + 1, 2);
    qraw.alias_summary{1,1} = 'Alias';
    qraw.alias_summary{1,2} = 'Expression';
    for i = 1:alias_count
        qraw.alias_summary{i+1,1} = qraw.alias_names{i};
        qraw.alias_summary{i+1,2} = qraw.alias_expressions{i};
    end
    fprintf('Alias summary created with %d aliases\n', alias_count);
end

% Step handling (simplified)
qraw.step.status = false;
for i = 1:length(qraw.info)
    if ~isempty(strfind(qraw.info{i}, 'stepped'))
        qraw.step.status = true;
        break;
    end
end

fprintf('\nParsing completed successfully!\n');
fprintf('Available in qraw structure:\n');
fprintf('  .data - Main data matrix (%d x %d)\n', size(qraw.data,1), size(qraw.data,2));
fprintf('  .var - Structure with individual variables\n');
if param_count > 0
    fprintf('  .parameters - Structure with parameter values\n');
    fprintf('  .param_summary - Cell array of parameters\n');
end
if alias_count > 0
    fprintf('  .aliases - Structure with alias expressions\n');
    fprintf('  .alias_summary - Cell array of aliases\n');
end

end
