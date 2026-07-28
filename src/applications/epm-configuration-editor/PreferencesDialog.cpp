// Copyright (c) Qualcomm Technologies, Inc. and/or its subsidiaries.
// SPDX-License-Identifier: BSD-3-Clause

#include "PreferencesDialog.h"

// EPM Configuration Editor
#include "EPMEditorDefines.h"
#include "EPMConfigurationApplication.h"

// QCommon
#include "ApplicationEnhancements.h"
#include "AlpacaSettings.h"

// Qt
#include <QFileDialog>

PreferencesDialog::PreferencesDialog
(
	QWidget* parent
) :
	QDialog(parent)
{
	setupUi(this);

	connect(this, &PreferencesDialog::preferencesChanged, EPMConfigurationApplication::epmConfigAppInstance(), &EPMConfigurationApplication::on_preferencesChanged);

	connect(this, &QDialog::accepted, this, &PreferencesDialog::on_accepted);
}

void PreferencesDialog::on__setToDefaultsButton_clicked()
{
}

void PreferencesDialog::on__browseForLogPathButton_clicked()
{
	QString currentDir = QDir::cleanPath(_logLocation->text());
	QString newLogLocation = QDir::cleanPath(QFileDialog::getExistingDirectory(this, "Select logs directory", currentDir));
	if (newLogLocation.isEmpty() == false)
	{
		if (newLogLocation.toLower() != currentDir.toLower())
		{
			_logLocation->setText(newLogLocation);
		}
	}
}

void PreferencesDialog::on_accepted()
{
	bool changed(false);

	if (changed)
		emit preferencesChanged(kEPMConfigurationGroup);
}

void PreferencesDialog::changeEvent(QEvent *e)
{
	QDialog::changeEvent(e);

	switch (e->type())
	{
	case QEvent::LanguageChange:
		retranslateUi(this);
		break;

	default:
		break;
	}
}
