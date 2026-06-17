%% Data Input/Output Configuration
filename_in = 'weibull_data.xlsx';  % Input data file name
filename_out = 'Weibull_Results.xlsx'; % Output results file name
rowRange = 'A1:D25'; % Target data range inside the Excel sheet

%% Read and Initialize Input Data
rawData = readmatrix(filename_in, 'Range', rowRange);

% Refresh the output file if it already exists
if exist(filename_out, 'file') 
    delete(filename_out);
end

%% Data Sorting and Grid Initialization           
midData = sort(rawData);   
num_rows = size(midData, 1);
num_cols = size(midData, 2);
x_grid_pdf = linspace(0, max(midData(:), [], 'omitnan'), 500)';

%% Allocate Matrices for Parameters and Coordinates
lnX = NaN(num_rows, num_cols);  % Experimental X coordinates (log scale)
lnY = NaN(num_rows, num_cols);  % Experimental Y coordinates (log scale)
lnY_theo = NaN(num_rows, num_cols); % Theoretical regression lines
wData = zeros(5, num_cols);     % Weibull & statistical parameters: (m, sigma, q05, q95, R^2)
 
%% Main Data Processing Loop
for r = 1:num_cols
    [X, Y, Y_th, W] = logPoints(midData, r);
    
    if ~isempty(X)
        lnX(1:length(X), r) = X; 
        lnY(1:length(Y), r) = Y;
        lnY_theo(1:length(Y_th), r) = Y_th; 
    else
        lnX(:, r) = NaN;
        lnY(:, r) = NaN;
        lnY_theo(:, r) = NaN;
    end
    
    wData(:, r) = W; 
end


%% Visualization Setup
% Determine global axis limits to standardize all plots
x_min = min(lnX(:), [], 'omitnan');
x_max = max(lnX(:), [], 'omitnan');
y_min = min([lnY(:); lnY_theo(:)], [], 'omitnan'); % Consider both data points and lines
y_max = max([lnY(:); lnY_theo(:)], [], 'omitnan');

% Add 5% padding around the boundaries for better visibility
x_lims = [x_min - 0.05*abs(x_min), x_max + 0.05*abs(x_max)];
y_lims = [y_min - 0.05*abs(y_min), y_max + 0.05*abs(y_max)];

% List of markers for different datasets
marker_list = {'o', 's', 'd', '^', 'v', '>', '<', 'p', 'h'};

%% Plotting Loop (Weibull Plots & Probability Density Functions)
for r = 1:num_cols
    % Extract current column data
    current_x = lnX(:, r);
    current_y = lnY(:, r);
    current_yth = lnY_theo(:, r);
    
    % Filter out NaN values
    valid_idx = ~isnan(current_x) & ~isnan(current_y);
    pure_x = current_x(valid_idx);
    pure_y = current_y(valid_idx);
    pure_yth = current_yth(valid_idx);
    
    % Skip the current column if it contains no valid data
    if isempty(pure_x)
        continue;
    end
    
    % Count valid data points for statistics
    real_num_points = length(pure_x);
    
    % Initialize a new figure window for each column
    figure('Name', sprintf('Column %d', r));
    subplot(2,1,1);
    hold on; 

    h_pts = plot(pure_x, pure_y, marker_list{r}, 'LineWidth', 1.5, 'MarkerFaceColor', 'auto');
    h_line = plot(pure_x, pure_yth, '-', 'LineWidth',2 , 'Color','red' );

    % Apply plot formatting and labels
    grid on;
    xlim(x_lims);
    ylim(y_lims);
    xlabel('ln(Kc)');
    ylabel('ln(-ln(1-F(Kc))');
    title(sprintf('Kc Weibull distribution - Column %d', r));
    
    % Calculate critical R^2 value based on sample size
    R2_crit = 1.0637 - 0.4174 / (real_num_points^0.3);

    % Construct the statistics string for the legend
    stats_text = sprintf(['Parameters:\n' ...
                           'Points: %d\n' ...
                           'm: %.4f\n' ...
                           'sigma: %.4f\n' ...
                           'q0.05: %.4f\n' ...
                           'q0.95: %.4f\n' ...
                           'R^2: %.4f\n' ...
                           'R^2_{crit}: %.4f'], ...
                           real_num_points, wData(1, r), wData(2, r), wData(3, r), wData(4, r), wData(5, r), R2_crit);
    
     legend([h_pts, h_line], {sprintf('Data (%d pts)', real_num_points), stats_text}, 'Location', 'best');
     hold off;

     subplot(2,1,2);
     hold on;
    current_raw = midData(:, r);
    pure_raw = current_raw(~isnan(current_raw));
    
    % Plot the empirical density histogram
    histogram(pure_raw, 'Normalization', 'pdf', 'FaceColor', [0.7 0.8 1], 'EdgeColor', 'none');
    
    % Calculate and plot the continuous theoretical PDF line
    % x_pdf = linspace(min(pure_raw)*0.8, max(pure_raw)*1.2, 200); % Grid for smooth line fitting
    pdf_theoretical = wblpdf(x_grid_pdf, wData(2, r), wData(1, r));   % Scale parameter (sigma) goes first!
    
    plot(x_grid_pdf, pdf_theoretical, 'r-', 'LineWidth', 2);
    
    % Apply formatting to the PDF subplot
    title(sprintf('PDF (Column %d)', r)); % Fixed variable reference: col -> r
    grid on;
    xlabel('Kc, Mpa*m^(1/2)'); 
    ylabel('Probability Density');
    hold off;
end

%% Export Parameter Summary to Excel
R2_crit_row = 1.0637 - 0.4174 ./ (arrayfun(@(x) real_num_points, 1:num_cols).^0.3); 
wData_extended = [wData; R2_crit_row]; 
row_names = {'m'; 'sigma'; 'q0.05'; 'q0.95'; 'R^2'; 'R^2_crit'};
col_names = arrayfun(@(x) sprintf('Column_%d', x), 1:num_cols, 'UniformOutput', false);
output_table = array2table(wData_extended, 'RowNames', row_names, 'VariableNames', col_names);
writetable(output_table, filename_out, 'WriteRowNames', true);

%% Helper Functions
function [logRowX, logRowY, logRowY_th, wRow] = logPoints(dataMat, colmnNum)
    % Extract target column
    processData = dataMat(:, colmnNum);
    
    % Remove NaN and non-positive values to avoid log errors
    processDataL = processData(~isnan(processData)); 
    processDataL = processDataL(processDataL > 0); 
    
    % Handle empty columns or invariant datasets
    if isempty(processDataL) || all(processDataL == processDataL(1))
        logRowX = []; 
        logRowY = [];
        logRowY_th = [];
        wRow = [NaN; NaN; NaN; NaN; NaN];
        return;
    end
    
    % Fit data to Weibull distribution
    [param, ci] = wblfit(processDataL);
    sigma_val = param(1); 
    m_val     = param(2); 
    
    % Calculate quantiles
    q05_val = wblinv(0.05, sigma_val, m_val);
    q95_val = wblinv(0.95, sigma_val, m_val);
    
    % Transform data to logarithmic scale (Weibull space)
    N = length(processDataL);
    i_rank = (1:N)';
    F_emp = (i_rank - 0.3) / (N + 0.4);  
    
    X_log = log(processDataL);              
    Y_log = log(-log(1 - F_emp));              
    Y_theoretical = m_val * X_log - m_val * log(sigma_val);
    
    % Calculate Coefficient of Determination (R-squared)
    SS_res = sum((Y_log - Y_theoretical).^2);
    SS_tot = sum((Y_log - mean(Y_log)).^2);
    R_squared = 1 - (SS_res / SS_tot);
    
    % Assign function outputs
    logRowX = X_log;
    logRowY = Y_log;
    logRowY_th = Y_theoretical; % Theoretical line for regression plot
    wRow = [m_val; sigma_val; q05_val; q95_val; R_squared]; 
end
