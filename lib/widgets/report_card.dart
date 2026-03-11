import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/models.dart';
import '../core/constants/app_colors.dart';
import '../core/utils/helpers.dart';

class ReportCard extends StatelessWidget {
  final ReportModel report;
  final VoidCallback? onTap;
  final bool showSubmitter;

  const ReportCard({
    super.key,
    required this.report,
    this.onTap,
    this.showSubmitter = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              _buildImage(),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _buildTypeBadge(),
                        const Spacer(),
                        _buildStatusBadge(),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      report.itemType,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.color_lens_outlined,
                          size: 14,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          report.itemColor,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 14,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            report.itemLocation,
                            style: Theme.of(context).textTheme.bodySmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.tag,
                          size: 14,
                          color: AppColors.primaryGreen,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          report.referenceId,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.primaryGreen,
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          Helpers.timeAgo(report.submissionDate),
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.textHint,
                                  ),
                        ),
                        if (report.isCenterSubmitted) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.info.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Center',
                              style: TextStyle(
                                fontSize: 10,
                                color: AppColors.info,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImage() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 80,
        height: 80,
        child: report.imageUrl != null
            ? CachedNetworkImage(
                imageUrl: report.imageUrl!,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: AppColors.background,
                  child: const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: AppColors.background,
                  child: const Icon(Icons.image_not_supported),
                ),
              )
            : Container(
                color: AppColors.background,
                child: const Icon(
                  Icons.image,
                  color: AppColors.textHint,
                  size: 32,
                ),
              ),
      ),
    );
  }

  Widget _buildTypeBadge() {
    final isLost = report.reportType == ReportType.lost;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isLost
            ? AppColors.error.withOpacity(0.1)
            : AppColors.success.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        isLost ? 'Lost' : 'Found',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: isLost ? AppColors.error : AppColors.success,
        ),
      ),
    );
  }

  Widget _buildStatusBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Helpers.getStatusColor(report.status).withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        Helpers.getStatusText(report.status),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Helpers.getStatusColor(report.status),
        ),
      ),
    );
  }
}
